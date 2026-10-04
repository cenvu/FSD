import Darwin
import Foundation

/// Cancellation state is protected entirely by `lock`; the finalization lock
/// is the same lock used by cancellation, so the terminal decision is made
/// atomically with respect to a late cancel request.
public final class CaptureCancellationToken: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false

    public init() {}

    public var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    public func cancel() {
        lock.lock()
        cancelled = true
        lock.unlock()
    }

    func withFinalizationLock<T>(_ body: (Bool) throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body(cancelled)
    }
}

public struct CaptureTotals: Sendable, Equatable {
    public let entries: Int64
    public let files: Int64
    public let folders: Int64
    public let logicalBytes: Int64
    public let allocatedBytes: Int64
    public let inaccessibleItems: Int64
    public let warningCount: Int64

    public init(entries: Int64 = 0, files: Int64 = 0, folders: Int64 = 0, logicalBytes: Int64 = 0, allocatedBytes: Int64 = 0, inaccessibleItems: Int64 = 0, warningCount: Int64 = 0) {
        self.entries = entries
        self.files = files
        self.folders = folders
        self.logicalBytes = logicalBytes
        self.allocatedBytes = allocatedBytes
        self.inaccessibleItems = inaccessibleItems
        self.warningCount = warningCount
    }
}

public enum SnapshotWriterError: Error, LocalizedError, Equatable {
    case database(CatalogDatabaseError)
    case snapshotNotFound(SnapshotID)
    case snapshotNotScanning(SnapshotID, SnapshotStatus)
    case parentMissing(String)
    case rootAlreadyWritten
    case terminalTransitionRejected(SnapshotStatus)
    case sourceRootNotWithinMount

    public var errorDescription: String? {
        switch self {
        case let .database(error): return error.localizedDescription
        case let .snapshotNotFound(id): return "Snapshot \(id) was not found."
        case let .snapshotNotScanning(id, status): return "Snapshot \(id) is \(status.rawValue), not scanning."
        case let .parentMissing(path): return "Parent entry was not persisted before child \(path)."
        case .rootAlreadyWritten: return "A snapshot may contain exactly one root entry."
        case let .terminalTransitionRejected(status): return "Snapshot cannot transition from \(status.rawValue)."
        case .sourceRootNotWithinMount: return "The selected capture root could not be proven to lie within its detected volume mount."
        }
    }
}

public final class SnapshotWriter {
    public static let scannerVersion = "fsd-scanner-m3"
    public let database: CatalogDatabase
    public let batchSize: Int

    public init(database: CatalogDatabase, batchSize: Int = 2000) {
        self.database = database
        self.batchSize = max(1, batchSize)
    }

    public func beginCapture(
        descriptor: FilesystemDescriptor,
        scanRootName: String,
        kind: SnapshotKind = .user,
        providerVersion: String = NativeMountedProvider.currentProviderVersion,
        token: CaptureCancellationToken = CaptureCancellationToken()
    ) throws -> SnapshotWriteSession {
        // Schema v9 source-root locator: computed before any catalog write so an
        // unprovable root fails the capture instead of being guessed.
        let rootRelativePath = try Self.rootRelativePath(for: descriptor)
        do {
            let snapshotID = try database.transaction {
                let volumeID = try ensureVolume(descriptor: descriptor)
                let sessionNumber = (try database.scalar(
                    "SELECT COALESCE(MAX(session_number), 0) + 1 FROM snapshots WHERE volume_id = ?",
                    bindings: [.integer(volumeID)]
                )?.int64Value ?? 1)
                try database.execute(
                    """
                    INSERT INTO snapshots (
                        volume_id, session_number, scan_root_name, mount_path_at_capture,
                        root_relative_path,
                        status, scanner_version, schema_version, normalization_version,
                        snapshot_kind, source_case_sensitivity, filesystem_provider,
                        provider_version, source_access_mode, filesystem_variant,
                        volume_display_name_at_capture, volume_identifier_at_capture,
                        volume_total_capacity_bytes_at_capture,
                        display_name, capture_policy_json, started_at, created_at, updated_at
                    ) VALUES (?, ?, ?, ?, ?, 'scanning', ?, ?, ?, ?, ?, 'native', ?, 'mounted', ?, ?, ?, ?, ?, '{}',
                              CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    """,
                    bindings: [
                        .integer(volumeID), .integer(sessionNumber), .text(scanRootName),
                        .text(descriptor.mountPath), .text(rootRelativePath), .text(Self.scannerVersion),
                        .integer(CatalogDatabase.currentSchemaVersion), .text(NormalizationVersion.current.rawValue),
                        .text(kind.rawValue), .text(descriptor.sourceCaseSensitivity.rawValue),
                        .text(providerVersion), .text(descriptor.filesystemType),
                        // Schema version 5 -- capture-time volume truth (ADR-023).
                        // These duplicate what `volumes` holds right now on
                        // purpose: `ensureVolume` below overwrites the registry
                        // row on every capture, and history must not show a
                        // later capture's values beside an earlier snapshot.
                        .text(descriptor.volumeName), .text(descriptor.volumeIdentifier),
                        descriptor.capacityBytes.map(DatabaseValue.integer) ?? .null,
                        .text(scanRootName)
                    ]
                )
                let id = SnapshotID(rawValue: try database.lastInsertRowID())
                try insertEntry(MetadataEntry.root(name: scanRootName), snapshotID: id)
                try updateTotals(for: id, entry: MetadataEntry.root(name: scanRootName))
                return id
            }
            return SnapshotWriteSession(writer: self, snapshotID: snapshotID, token: token, batchSize: batchSize)
        } catch let error as SnapshotWriterError {
            throw error
        } catch let error as CatalogDatabaseError {
            throw SnapshotWriterError.database(error)
        }
    }

    /// Normalized lexical path from the detected mount root to the selected
    /// root, stored once as an immutable capture fact (`""` for a mount-root
    /// capture). Relative, never `.`/`..`. The FINAL root-locator contract:
    /// direct lexical containment needs no alias lookup and no identity proof;
    /// otherwise POSIX `realpath` canonicalizes the selected capture root only,
    /// exactly one candidate (mount plus canonical components) is built, and it
    /// is accepted only after a no-follow walk from the mount root lands on the
    /// same filesystem object (st_dev and st_ino). Anything else fails capture;
    /// nothing is guessed and no second candidate is ever attempted.
    static func rootRelativePath(for descriptor: FilesystemDescriptor) throws -> String {
        let filesystem = DarwinBoundedSourceFilesystem()
        guard let mountPath = lexicalAbsolutePath(descriptor.mountPath),
              let rootPath = lexicalAbsolutePath(descriptor.rootURL.path)
        else { throw SnapshotWriterError.sourceRootNotWithinMount }

        // STAGE A — direct representation. Pure lexical containment of the
        // selected root beneath the physical mount. No alias lookup, no
        // object-identity proof, no filesystem I/O of any kind.
        if let direct = remainder(of: rootPath, under: mountPath) {
            guard let components = ClassificationSourcePath.components(of: direct, allowEmpty: true) else {
                throw SnapshotWriterError.sourceRootNotWithinMount
            }
            return components.joined(separator: "/")
        }

        // STAGE B — POSIX canonical selected root only. Resolves ordinary
        // symlinks and dot components of the capture root. Never entries, never
        // provider-visible, never used after capture to follow an entry symlink.
        guard let canonical = realPath(of: rootPath) else {
            throw SnapshotWriterError.sourceRootNotWithinMount
        }

        // STAGE C — exactly one physical candidate: the mount joined with the
        // canonical absolute components minus the leading "/". No raw-presentation
        // fallback, no mapping table, no second candidate.
        guard let candidate = physicalCandidate(mountPath: mountPath, canonicalRoot: canonical),
              let components = ClassificationSourcePath.components(of: candidate, allowEmpty: true)
        else { throw SnapshotWriterError.sourceRootNotWithinMount }

        // STAGE D — same-object proof. Both ends must exist as directories and
        // the no-follow walk from the mount root must land on the canonical
        // root's own filesystem object (st_dev and st_ino).
        guard let canonicalStat = try? filesystem.statFollowing(path: canonical),
              canonicalStat.kind == .directory,
              provesDirectory(mountPath: mountPath, components: components, equals: canonicalStat, using: filesystem)
        else { throw SnapshotWriterError.sourceRootNotWithinMount }

        return components.joined(separator: "/")
    }

    /// The single physical candidate for a canonical selected root: the mount
    /// path joined with the canonical absolute components minus the leading
    /// "/". Returns nil unless the result stays lexically beneath the mount.
    /// There is deliberately no plural form; callers must never retry with a
    /// raw-presentation or otherwise alternate candidate.
    static func physicalCandidate(mountPath: String, canonicalRoot: String) -> String? {
        guard canonicalRoot.hasPrefix("/") else { return nil }
        let stripped = String(canonicalRoot.dropFirst())
        let candidate = mountPath == "/" ? "/" + stripped : mountPath + "/" + stripped
        guard remainder(of: candidate, under: mountPath) != nil else { return nil }
        return stripped
    }

    private static func lexicalAbsolutePath(_ path: String) -> String? {
        guard path.hasPrefix("/") else { return nil }
        let standardized = URL(fileURLWithPath: path).standardizedFileURL.path
        return standardized.hasPrefix("/") ? standardized : nil
    }

    private static func remainder(of path: String, under mount: String) -> String? {
        if mount == "/" { return String(path.dropFirst()) }
        if path == mount { return "" }
        let prefix = mount + "/"
        return path.hasPrefix(prefix) ? String(path.dropFirst(prefix.count)) : nil
    }

    private static func realPath(of path: String) -> String? {
        guard let resolved = Darwin.realpath(path, nil) else { return nil }
        defer { free(resolved) }
        return String(cString: resolved)
    }

    private static func provesDirectory(
        mountPath: String,
        components: [String],
        equals target: ClassificationFileStat,
        using filesystem: DarwinBoundedSourceFilesystem
    ) -> Bool {
        var descriptors: [Int32] = []
        defer { for descriptor in descriptors.reversed() { filesystem.close(descriptor: descriptor) } }
        do {
            var current = try filesystem.openMountRoot(path: mountPath)
            descriptors.append(current)
            for component in components {
                current = try filesystem.openDirectory(parent: current, name: component)
                descriptors.append(current)
            }
            let reached = try filesystem.stat(descriptor: current)
            return reached.kind == .directory && reached.device == target.device && reached.inode == target.inode
        } catch {
            return false
        }
    }

    fileprivate func ensureVolume(descriptor: FilesystemDescriptor) throws -> Int64 {
        let existing: DatabaseValue?
        if descriptor.volumeIdentifier.hasPrefix("native-root:") {
            existing = try database.scalar(
                "SELECT id FROM volumes WHERE fallback_fingerprint = ? LIMIT 1",
                bindings: [.text(descriptor.volumeIdentifier)]
            )
        } else {
            existing = try database.scalar(
                "SELECT id FROM volumes WHERE persistent_uuid = ? LIMIT 1",
                bindings: [.text(descriptor.volumeIdentifier)]
            )
        }
        if let id = existing?.int64Value {
            try database.execute(
                "UPDATE volumes SET display_name = ?, filesystem_type = ?, total_capacity_bytes = ?, last_seen_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
                bindings: [
                    .text(descriptor.volumeName), .text(descriptor.filesystemType),
                    descriptor.capacityBytes.map(DatabaseValue.integer) ?? .null, .integer(id)
                ]
            )
            return id
        }
        try database.execute(
            """
            INSERT INTO volumes (
                persistent_uuid, fallback_fingerprint, display_name, filesystem_type,
                total_capacity_bytes, first_seen_at, last_seen_at, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """,
            bindings: [
                descriptor.volumeIdentifier.hasPrefix("native-root:") ? .null : .text(descriptor.volumeIdentifier),
                .text(descriptor.volumeIdentifier), .text(descriptor.volumeName), .text(descriptor.filesystemType),
                descriptor.capacityBytes.map(DatabaseValue.integer) ?? .null
            ]
        )
        return try database.lastInsertRowID()
    }

    fileprivate func insertEntry(_ entry: MetadataEntry, snapshotID: SnapshotID) throws {
        let parentID: DatabaseValue
        if let parentPath = entry.parentRelativePath {
            guard let value = try database.scalar(
                "SELECT id FROM entries WHERE snapshot_id = ? AND relative_path = ? LIMIT 1",
                bindings: [.integer(snapshotID.rawValue), .text(parentPath)]
            )?.int64Value else {
                throw SnapshotWriterError.parentMissing(parentPath)
            }
            parentID = .integer(value)
        } else {
            parentID = .null
        }
        try database.execute(
            """
            INSERT INTO entries (
                snapshot_id, parent_id, relative_path, case_preserving_path, case_folded_path,
                name, case_preserving_name, case_folded_name, file_extension, item_type,
                logical_size_bytes, allocated_size_bytes, created_at_source, modified_at_source,
                content_type_identifier, resource_identifier, symlink_target, is_hidden, is_package,
                is_inaccessible, sort_key, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
            """,
            bindings: [
                .integer(snapshotID.rawValue), parentID, .text(entry.relativePath), .text(entry.casePreservingPath),
                .text(entry.caseFoldedPath), .text(entry.name), .text(entry.casePreservingName), .text(entry.caseFoldedName),
                entry.fileExtension.map(DatabaseValue.text) ?? .null, .text(entry.itemKind.rawValue),
                entry.logicalSizeBytes.map(DatabaseValue.integer) ?? .null, entry.allocatedSizeBytes.map(DatabaseValue.integer) ?? .null,
                entry.createdAt.map(Self.dateValue) ?? .null, entry.modifiedAt.map(Self.dateValue) ?? .null,
                entry.contentTypeIdentifier.map(DatabaseValue.text) ?? .null, entry.resourceIdentifier.map(DatabaseValue.blob) ?? .null,
                entry.symlinkTarget.map(DatabaseValue.text) ?? .null, .integer(entry.isHidden ? 1 : 0), .integer(entry.isPackage ? 1 : 0),
                .integer(entry.isInaccessible ? 1 : 0), .text(entry.sortKey)
            ]
        )
    }

    fileprivate func updateTotals(for snapshotID: SnapshotID, entry: MetadataEntry) throws {
        let fileDelta: Int64 = entry.itemKind == .file ? 1 : 0
        let folderDelta: Int64 = (entry.itemKind == .directory || entry.itemKind == .package) ? 1 : 0
        try database.execute(
            """
            UPDATE snapshots SET
                total_files = total_files + ?, total_folders = total_folders + ?,
                total_logical_bytes = total_logical_bytes + ?, total_allocated_bytes = total_allocated_bytes + ?,
                inaccessible_items = inaccessible_items + ?, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
            """,
            bindings: [
                .integer(fileDelta), .integer(folderDelta), .integer(entry.logicalSizeBytes ?? 0),
                .integer(entry.allocatedSizeBytes ?? 0), .integer(entry.isInaccessible ? 1 : 0), .integer(snapshotID.rawValue)
            ]
        )
    }

    fileprivate func insertIssue(_ issue: ScanIssue, snapshotID: SnapshotID) throws {
        let entryID = try database.scalar(
            "SELECT id FROM entries WHERE snapshot_id = ? AND relative_path = ? LIMIT 1",
            bindings: [.integer(snapshotID.rawValue), .text(issue.relativePath)]
        )?.int64Value
        try database.execute(
            """
            INSERT INTO scan_issues (
                snapshot_id, entry_id, relative_path, error_domain, error_code,
                severity, source, message, was_skipped, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
            """,
            bindings: [
                .integer(snapshotID.rawValue), entryID.map(DatabaseValue.integer) ?? .null, .text(issue.relativePath),
                issue.errorDomain.map(DatabaseValue.text) ?? .null, issue.errorCode.map { .integer(Int64($0)) } ?? .null,
                .text(issue.severity), .text(issue.source), .text(issue.message), .integer(issue.wasSkipped ? 1 : 0)
            ]
        )
    }

    fileprivate func currentStatus(_ snapshotID: SnapshotID) throws -> SnapshotStatus {
        guard let raw = try database.scalar(
            "SELECT status FROM snapshots WHERE id = ?", bindings: [.integer(snapshotID.rawValue)]
        )?.stringValue, let status = SnapshotStatus(rawValue: raw) else {
            throw SnapshotWriterError.snapshotNotFound(snapshotID)
        }
        return status
    }

    fileprivate func setTerminalStatus(_ snapshotID: SnapshotID, to status: SnapshotStatus) throws {
        try database.transaction {
            let current = try currentStatus(snapshotID)
            guard current == .scanning else {
                throw SnapshotWriterError.terminalTransitionRejected(current)
            }
            let warningCount = try database.scalar(
                "SELECT COUNT(*) FROM scan_issues WHERE snapshot_id = ? AND severity IN ('warning', 'error')",
                bindings: [.integer(snapshotID.rawValue)]
            )?.int64Value ?? 0
            try database.execute(
                "UPDATE snapshots SET status = ?, warning_count = ?, completed_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
                bindings: [.text(status.rawValue), .integer(warningCount), .integer(snapshotID.rawValue)]
            )
        }
    }

    private static func dateValue(_ date: Date) -> DatabaseValue {
        .text(String(date.timeIntervalSince1970))
    }
}

public final class SnapshotWriteSession {
    public let snapshotID: SnapshotID
    public let token: CaptureCancellationToken
    private let writer: SnapshotWriter
    private let batchSize: Int
    private var isFinished = false
    private var pending: [MetadataEntry] = []
    private var warningCount: Int64 = 0

    fileprivate init(writer: SnapshotWriter, snapshotID: SnapshotID, token: CaptureCancellationToken, batchSize: Int) {
        self.writer = writer
        self.snapshotID = snapshotID
        self.token = token
        self.batchSize = batchSize
    }

    public func append(_ entry: MetadataEntry) throws {
        try append(contentsOf: [entry])
    }

    public func append(contentsOf entries: [MetadataEntry]) throws {
        guard !entries.isEmpty else { return }
        guard !isFinished else { throw SnapshotWriterError.terminalTransitionRejected(.complete) }
        pending.append(contentsOf: entries)
        while pending.count >= batchSize {
            let batch = Array(pending.prefix(batchSize))
            pending.removeFirst(batchSize)
            try persist(batch)
        }
    }

    public func append(issue: ScanIssue) throws {
        guard !isFinished else { throw SnapshotWriterError.terminalTransitionRejected(.complete) }
        try flush()
        try writer.database.transaction {
            try writer.insertIssue(issue, snapshotID: snapshotID)
        }
        warningCount += issue.severity == "info" ? 0 : 1
    }

    public func flush() throws {
        guard !pending.isEmpty else { return }
        let batch = pending
        pending.removeAll(keepingCapacity: true)
        try persist(batch)
    }

    public func finish(preferredStatus: SnapshotStatus) throws {
        try token.withFinalizationLock { cancellationWon in
            if isFinished { throw SnapshotWriterError.terminalTransitionRejected(preferredStatus) }
            try flush()
            let finalStatus = cancellationWon ? .cancelled : preferredStatus
            guard finalStatus != .scanning else { throw SnapshotWriterError.terminalTransitionRejected(.scanning) }
            try writer.setTerminalStatus(snapshotID, to: finalStatus)
            isFinished = true
        }
    }

    private func persist(_ batch: [MetadataEntry]) throws {
        try writer.database.transaction {
            let status = try writer.currentStatus(snapshotID)
            guard status == .scanning else { throw SnapshotWriterError.snapshotNotScanning(snapshotID, status) }
            for entry in batch {
                try writer.insertEntry(entry, snapshotID: snapshotID)
                try writer.updateTotals(for: snapshotID, entry: entry)
            }
        }
    }
}
