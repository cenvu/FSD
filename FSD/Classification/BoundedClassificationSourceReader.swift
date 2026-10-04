import Darwin
import Foundation

// MARK: - Reader-private filesystem seam
//
// Everything in this section is the *reader's* authority. It is internal to the
// module, never passed to a provider, and exists so tests can deterministically
// simulate disappearance, permission failure, substitution and read counts
// without granting any filesystem capability to classification providers.

struct ClassificationPOSIXFailure: Error, Equatable {
    let code: Int32
}

enum ClassificationLiveKind: Equatable {
    case regular
    case directory
    case symlink
    case other
}

struct ClassificationFileStat: Equatable {
    var device: Int64
    var inode: UInt64
    var kind: ClassificationLiveKind
    var size: Int64
}

/// Descriptor-relative, no-follow primitives. Each directory component is
/// opened relative to its already-validated parent with `O_NOFOLLOW`, so a
/// symlink swapped in anywhere along the stored path cannot redirect the walk.
protocol BoundedSourceFilesystem {
    func openMountRoot(path: String) throws -> Int32
    func openDirectory(parent: Int32, name: String) throws -> Int32
    func statNoFollow(parent: Int32, name: String) throws -> ClassificationFileStat
    func openRegularFile(parent: Int32, name: String) throws -> Int32
    func stat(descriptor: Int32) throws -> ClassificationFileStat
    /// Performs exactly one `read(2)` at the descriptor's current offset (zero
    /// for a freshly opened file). Never loops, retries or issues a second read.
    func readOnce(descriptor: Int32, into buffer: UnsafeMutableRawBufferPointer) throws -> Int
    func close(descriptor: Int32)
}

struct DarwinBoundedSourceFilesystem: BoundedSourceFilesystem {
    init() {}

    func openMountRoot(path: String) throws -> Int32 {
        let descriptor = Darwin.open(path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard descriptor >= 0 else { throw ClassificationPOSIXFailure(code: errno) }
        return descriptor
    }

    func openDirectory(parent: Int32, name: String) throws -> Int32 {
        let descriptor = Darwin.openat(parent, name, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard descriptor >= 0 else { throw ClassificationPOSIXFailure(code: errno) }
        return descriptor
    }

    func statNoFollow(parent: Int32, name: String) throws -> ClassificationFileStat {
        var info = Darwin.stat()
        guard Darwin.fstatat(parent, name, &info, AT_SYMLINK_NOFOLLOW) == 0 else {
            throw ClassificationPOSIXFailure(code: errno)
        }
        return Self.convert(info)
    }

    /// `O_NONBLOCK` guarantees that a path swapped to a FIFO between the
    /// `lstat` and the open can never hang the caller; it has no effect on the
    /// regular-file read that follows.
    func openRegularFile(parent: Int32, name: String) throws -> Int32 {
        let descriptor = Darwin.openat(parent, name, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_NOCTTY | O_CLOEXEC)
        guard descriptor >= 0 else { throw ClassificationPOSIXFailure(code: errno) }
        return descriptor
    }

    func stat(descriptor: Int32) throws -> ClassificationFileStat {
        var info = Darwin.stat()
        guard Darwin.fstat(descriptor, &info) == 0 else { throw ClassificationPOSIXFailure(code: errno) }
        return Self.convert(info)
    }

    func readOnce(descriptor: Int32, into buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        let count = Darwin.read(descriptor, buffer.baseAddress, buffer.count)
        guard count >= 0 else { throw ClassificationPOSIXFailure(code: errno) }
        return count
    }

    func close(descriptor: Int32) {
        _ = Darwin.close(descriptor)
    }

    /// Following `stat(2)` used only by the capture-time locator proof.
    func statFollowing(path: String) throws -> ClassificationFileStat {
        var info = Darwin.stat()
        guard Darwin.fstatat(AT_FDCWD, path, &info, 0) == 0 else { throw ClassificationPOSIXFailure(code: errno) }
        return Self.convert(info)
    }

    private static func convert(_ info: Darwin.stat) -> ClassificationFileStat {
        let kind: ClassificationLiveKind
        switch info.st_mode & S_IFMT {
        case S_IFREG: kind = .regular
        case S_IFDIR: kind = .directory
        case S_IFLNK: kind = .symlink
        default: kind = .other
        }
        return ClassificationFileStat(
            device: Int64(info.st_dev), inode: UInt64(info.st_ino), kind: kind, size: Int64(info.st_size)
        )
    }
}

// MARK: - Stored relative-path validation

/// Validation of stored relative path components. A candidate source location
/// is only ever the ordered component list of a validated root locator plus a
/// validated entry path; no absolute candidate string is built, standardized or
/// symlink-resolved.
enum ClassificationSourcePath {
    static let maximumComponentBytes = 255
    static let maximumComponentCount = 1024

    /// Returns nil for anything that is not a clean, relative, `/`-separated
    /// list of non-empty components (absolute, `.`, `..`, empty or NUL-bearing
    /// component, over-long component, or excessive depth).
    static func components(of relativePath: String, allowEmpty: Bool) -> [String]? {
        if relativePath.isEmpty { return allowEmpty ? [] : nil }
        let parts = relativePath.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard parts.count <= maximumComponentCount else { return nil }
        for part in parts {
            guard !part.isEmpty, part != ".", part != "..",
                  !part.utf8.contains(0), part.utf8.count <= maximumComponentBytes else { return nil }
        }
        return parts
    }
}

// MARK: - Bounded classification source reader

/// What the FSD reader can decide *before* any provider exists.
enum BoundedClassificationSourceOutcome: Sendable, Hashable {
    /// The single bounded prefix, wrapped in the Data-only provider request.
    case prefix(LocalClassificationRequest)
    case failed
    case sourceChanged
    case unsupportedEntry
    case unavailable
    case cancelled

    /// The typed result for every outcome that ends before a provider call.
    var preProviderResult: LocalClassificationProviderResult? {
        switch self {
        case .prefix: return nil
        case .failed: return .failed
        case .sourceChanged: return .sourceChanged
        case .unsupportedEntry: return .unsupportedEntry
        case .unavailable: return .unavailable
        case .cancelled: return .cancelled
        }
    }
}

/// Owns ALL classification source access; a provider owns none.
///
/// For one selected entry it re-resolves the captured mount, validates exact
/// volume identity, walks validated stored components with descriptor-relative
/// `O_NOFOLLOW` opens, confirms a regular file via `lstat`/`fstat`, performs one
/// `read(2)` of at most 4096 bytes at offset zero, revalidates identity, and
/// only then hands back bounded immutable bytes. It never hashes, persists,
/// logs, follows a symlink, reads a tail, or issues a second content read.
final class BoundedClassificationSourceReader {
    static let maximumPrefixBytes = LocalClassificationRequest.maximumByteCount
    static let minimumLocatorSchemaVersion: Int64 = 9

    /// Points at which an observed cancellation stops the flow.
    enum CancellationBoundary: Equatable {
        case beforeResolution
        case beforeRead
        case afterOpen
        case afterRead
    }

    private let database: CatalogDatabase
    private let detectMount: (URL) throws -> FilesystemDescriptor
    private let filesystem: any BoundedSourceFilesystem
    private let isCancelled: (CancellationBoundary) -> Bool

    convenience init(database: CatalogDatabase) {
        self.init(
            database: database,
            detectMount: { try FilesystemDetector().detect(root: $0) },
            filesystem: DarwinBoundedSourceFilesystem(),
            isCancelled: { _ in Task.isCancelled }
        )
    }

    /// Injection seam for deterministic tests. It lives behind this reader and
    /// is never reachable from a provider.
    init(
        database: CatalogDatabase,
        detectMount: @escaping (URL) throws -> FilesystemDescriptor,
        filesystem: any BoundedSourceFilesystem,
        isCancelled: @escaping (CancellationBoundary) -> Bool
    ) {
        self.database = database
        self.detectMount = detectMount
        self.filesystem = filesystem
        self.isCancelled = isCancelled
    }

    /// Only a local catalog read can throw; every source-side condition is a
    /// typed outcome.
    func readPrefix(forEntryID entryID: Int64) throws -> BoundedClassificationSourceOutcome {
        if isCancelled(.beforeResolution) { return .cancelled }
        guard let context = try loadContext(entryID: entryID) else { return .unavailable }

        // Snapshot / source eligibility. Anything without a trustworthy schema-v9
        // locator and recorded identity fails closed; nothing is backfilled.
        guard context.schemaVersion >= Self.minimumLocatorSchemaVersion,
              context.snapshotStatus != "scanning",
              context.filesystemProvider == "native",
              context.sourceAccessMode == "mounted",
              let recordedMount = context.mountPath, recordedMount.hasPrefix("/"),
              let recordedIdentity = context.volumeIdentifier, !recordedIdentity.isEmpty,
              let rootComponents = ClassificationSourcePath.components(of: context.rootRelativePath, allowEmpty: true)
        else { return .unavailable }

        // Initial source resolution. A source that cannot be resolved at all is
        // unavailable; a present source with another identity has changed.
        let resolved: FilesystemDescriptor
        do {
            resolved = try detectMount(URL(fileURLWithPath: recordedMount, isDirectory: true))
        } catch {
            return .unavailable
        }
        guard resolved.volumeIdentifier == recordedIdentity, resolved.mountPath == recordedMount else {
            return .sourceChanged
        }

        // Stored entry kind is classified before any content I/O. Only a stored
        // regular file may be read; directories, packages, symlinks and other
        // items (including the root entry) are unsupported.
        guard context.storedKind == FilesystemItemKind.file.rawValue, !context.isPackage else {
            return .unsupportedEntry
        }
        guard let entryComponents = ClassificationSourcePath.components(of: context.entryRelativePath, allowEmpty: false),
              let fileName = entryComponents.last
        else { return .unavailable }
        let directoryComponents = rootComponents + entryComponents.dropLast()

        if isCancelled(.beforeRead) { return .cancelled }

        let initial = DescriptorBag(filesystem: filesystem)
        defer { initial.closeAll() }
        let walk: DirectoryWalk
        switch walkDirectories(mountPath: recordedMount, components: directoryComponents, bag: initial, expected: nil) {
        case let .success(value): walk = value
        case let .failure(outcome): return outcome
        }

        let candidate: ClassificationFileStat
        do {
            candidate = try filesystem.statNoFollow(parent: walk.parent, name: fileName)
        } catch let failure as ClassificationPOSIXFailure {
            return outcome(forErrno: failure.code)
        } catch {
            return .failed
        }
        switch candidate.kind {
        case .regular: break
        case .directory, .symlink, .other: return .unsupportedEntry
        }
        guard candidate.device == walk.mountDevice else { return .sourceChanged }

        let descriptor: Int32
        do {
            descriptor = initial.adopt(try filesystem.openRegularFile(parent: walk.parent, name: fileName))
        } catch let failure as ClassificationPOSIXFailure {
            return outcome(forErrno: failure.code)
        } catch {
            return .failed
        }
        if isCancelled(.afterOpen) { return .cancelled }

        let opened: ClassificationFileStat
        do {
            opened = try filesystem.stat(descriptor: descriptor)
        } catch let failure as ClassificationPOSIXFailure {
            return outcome(forErrno: failure.code)
        } catch {
            return .failed
        }
        guard opened.kind == .regular, opened.device == candidate.device, opened.inode == candidate.inode else {
            return .sourceChanged
        }

        // Exactly one content read, at most 4096 bytes, from offset zero.
        var buffer = [UInt8](repeating: 0, count: Self.maximumPrefixBytes)
        let readCount: Int
        do {
            readCount = try buffer.withUnsafeMutableBytes { try filesystem.readOnce(descriptor: descriptor, into: $0) }
        } catch {
            // Cancellation observed at the read boundary wins over mapping the
            // read failure to another terminal outcome. The read is never retried.
            if isCancelled(.afterRead) { return .cancelled }
            if let failure = error as? ClassificationPOSIXFailure {
                return outcome(forErrno: failure.code)
            }
            return .failed
        }
        guard readCount >= 0, readCount <= Self.maximumPrefixBytes else { return .failed }

        // Cancellation observed once the read attempt returned wins over mapping
        // the returned count or any later path error to another terminal outcome.
        // Earlier pre-read sourceChanged/unsupported results stand: a cancellation
        // that had not yet occurred never masks them.
        if isCancelled(.afterRead) { return .cancelled }

        // A short result is accepted only when the file genuinely had fewer
        // bytes. Fewer bytes than the pre-read size promised is never topped up
        // with a second read: truncation means the source changed, any other
        // shortfall is a failed read.
        let expected = min(opened.size, Int64(Self.maximumPrefixBytes))
        if Int64(readCount) < expected {
            if let after = try? filesystem.stat(descriptor: descriptor), after.size < expected {
                return .sourceChanged
            }
            return .failed
        }

        // Post-read revalidation: same object, same source, same path.
        let afterRead: ClassificationFileStat
        do {
            afterRead = try filesystem.stat(descriptor: descriptor)
        } catch let failure as ClassificationPOSIXFailure {
            return outcome(forErrno: failure.code)
        } catch {
            return .failed
        }
        guard afterRead.kind == .regular, afterRead.device == opened.device, afterRead.inode == opened.inode,
              afterRead.size >= Int64(readCount)
        else { return .sourceChanged }

        guard let again = try? detectMount(URL(fileURLWithPath: recordedMount, isDirectory: true)),
              again.volumeIdentifier == recordedIdentity, again.mountPath == recordedMount
        else { return .sourceChanged }

        let revalidation = DescriptorBag(filesystem: filesystem)
        defer { revalidation.closeAll() }
        let secondWalk: DirectoryWalk
        switch walkDirectories(
            mountPath: recordedMount, components: directoryComponents, bag: revalidation, expected: walk.identities
        ) {
        case let .success(value): secondWalk = value
        case let .failure(outcome): return outcome
        }
        let confirmed: ClassificationFileStat
        do {
            confirmed = try filesystem.statNoFollow(parent: secondWalk.parent, name: fileName)
        } catch let failure as ClassificationPOSIXFailure {
            return outcome(forErrno: failure.code)
        } catch {
            return .failed
        }
        guard confirmed.kind == .regular, confirmed.device == opened.device, confirmed.inode == opened.inode else {
            return .sourceChanged
        }

        if isCancelled(.afterRead) { return .cancelled }

        guard let request = LocalClassificationRequest(boundedPrefix: Data(buffer.prefix(readCount))) else {
            return .failed
        }
        return .prefix(request)
    }

    // MARK: Walk

    private struct DirectoryWalk {
        let parent: Int32
        let mountDevice: Int64
        let identities: [ClassificationFileStat]
    }

    private enum WalkResult {
        case success(DirectoryWalk)
        case failure(BoundedClassificationSourceOutcome)
    }

    /// Opens the mount root and then each stored directory component relative
    /// to its parent with `O_NOFOLLOW`. Every directory must stay on the mount's
    /// device; on revalidation each must also be the very same directory object.
    private func walkDirectories(
        mountPath: String,
        components: [String],
        bag: DescriptorBag,
        expected: [ClassificationFileStat]?
    ) -> WalkResult {
        var identities: [ClassificationFileStat] = []
        do {
            func step(_ open: () throws -> Int32) throws -> (Int32, ClassificationFileStat) {
                do {
                    let descriptor = bag.adopt(try open())
                    let info = try filesystem.stat(descriptor: descriptor)
                    guard info.kind == .directory else { throw WalkAbort(outcome: .sourceChanged) }
                    return (descriptor, info)
                } catch let failure as ClassificationPOSIXFailure {
                    throw WalkAbort(outcome: outcome(forErrno: failure.code))
                }
            }

            let (rootDescriptor, rootInfo) = try step { try filesystem.openMountRoot(path: mountPath) }
            identities.append(rootInfo)
            var parent = rootDescriptor
            for component in components {
                let (descriptor, info) = try step { try filesystem.openDirectory(parent: parent, name: component) }
                guard info.device == rootInfo.device else { return .failure(.sourceChanged) }
                identities.append(info)
                parent = descriptor
            }
            if let expected {
                guard identities.count == expected.count,
                      zip(identities, expected).allSatisfy({ $0.device == $1.device && $0.inode == $1.inode })
                else { return .failure(.sourceChanged) }
            }
            return .success(DirectoryWalk(parent: parent, mountDevice: rootInfo.device, identities: identities))
        } catch let abort as WalkAbort {
            return .failure(abort.outcome)
        } catch {
            return .failure(.failed)
        }
    }

    private struct WalkAbort: Error {
        let outcome: BoundedClassificationSourceOutcome
    }

    /// Source disappearance or substitution after validation is `sourceChanged`;
    /// permission and I/O failure with the source still identified is `failed`.
    private func outcome(forErrno code: Int32) -> BoundedClassificationSourceOutcome {
        switch code {
        case ENOENT, ENOTDIR, ELOOP, ESTALE, ENXIO, ENODEV: return .sourceChanged
        default: return .failed
        }
    }

    // MARK: Catalog context

    private struct SourceContext {
        let entryRelativePath: String
        let storedKind: String
        let isPackage: Bool
        let schemaVersion: Int64
        let snapshotStatus: String
        let filesystemProvider: String
        let sourceAccessMode: String
        let rootRelativePath: String
        let mountPath: String?
        let volumeIdentifier: String?
    }

    private func loadContext(entryID: Int64) throws -> SourceContext? {
        let rows = try database.query(
            """
            SELECT e.relative_path, e.item_type, e.is_package, s.schema_version, s.status,
                   s.filesystem_provider, s.source_access_mode, s.root_relative_path,
                   s.mount_path_at_capture, s.volume_identifier_at_capture
            FROM entries e JOIN snapshots s ON s.id = e.snapshot_id
            WHERE e.id = ? LIMIT 1
            """,
            bindings: [.integer(entryID)]
        )
        guard let row = rows.first,
              let relativePath = row["relative_path"]?.stringValue,
              let kind = row["item_type"]?.stringValue,
              let schemaVersion = row["schema_version"]?.int64Value,
              let status = row["status"]?.stringValue,
              let provider = row["filesystem_provider"]?.stringValue,
              let accessMode = row["source_access_mode"]?.stringValue,
              let rootRelativePath = row["root_relative_path"]?.stringValue
        else { return nil }
        return SourceContext(
            entryRelativePath: relativePath,
            storedKind: kind,
            isPackage: (row["is_package"]?.int64Value ?? 0) != 0,
            schemaVersion: schemaVersion,
            snapshotStatus: status,
            filesystemProvider: provider,
            sourceAccessMode: accessMode,
            rootRelativePath: rootRelativePath,
            mountPath: row["mount_path_at_capture"]?.stringValue,
            volumeIdentifier: row["volume_identifier_at_capture"]?.stringValue
        )
    }
}

/// Tracks every descriptor opened during one walk so each is closed exactly once.
private final class DescriptorBag {
    private let filesystem: any BoundedSourceFilesystem
    private var descriptors: [Int32] = []

    init(filesystem: any BoundedSourceFilesystem) {
        self.filesystem = filesystem
    }

    func adopt(_ descriptor: Int32) -> Int32 {
        descriptors.append(descriptor)
        return descriptor
    }

    func closeAll() {
        for descriptor in descriptors.reversed() { filesystem.close(descriptor: descriptor) }
        descriptors.removeAll()
    }
}
