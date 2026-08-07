import Foundation
@testable import FSD

/// Builds complete snapshots from synthetic entry data, bypassing the
/// filesystem. Entries are inserted with explicit ids through the same schema
/// and triggers the scanner uses (a snapshot may only complete with exactly
/// one root and a supported normalization version), so the comparison engine
/// exercises the production invariants without touching a physical source.
enum SyntheticSnapshot {
    /// Creates a volume row (if absent) and a `scanning` snapshot.
    static func createSnapshot(
        database: CatalogDatabase,
        volumeID: Int64,
        session: Int64,
        sensitivity: SourceCaseSensitivity = .sensitive,
        kind: SnapshotKind = .user,
        name: String = "Root",
        normalizationVersion: NormalizationVersion = .current
    ) throws -> SnapshotID {
        let repository = SnapshotRepository(database: database)
        let volumeExists = try database.scalar(
            "SELECT 1 FROM volumes WHERE id = ? LIMIT 1", bindings: [.integer(volumeID)]
        )?.int64Value == 1
        if !volumeExists {
            try repository.createVolume(id: volumeID, displayName: "Volume \(volumeID)")
        }
        return try repository.createSnapshot(
            volumeID: volumeID,
            sessionNumber: session,
            scanRootName: name,
            normalizationVersion: normalizationVersion,
            kind: kind,
            sourceCaseSensitivity: sensitivity
        )
    }

    struct SeedEntry {
        let id: Int64
        let parentID: Int64?
        let relativePath: String
        let name: String
        let itemKind: FilesystemItemKind
        let logicalSizeBytes: Int64?
        let allocatedSizeBytes: Int64?
        let modifiedAtSource: String?
        let createdAtSource: String?
        let isHidden: Bool
        let isPackage: Bool
        let isInaccessible: Bool

        init(
            id: Int64,
            parentID: Int64?,
            relativePath: String,
            name: String,
            itemKind: FilesystemItemKind = .file,
            logicalSizeBytes: Int64? = nil,
            allocatedSizeBytes: Int64? = nil,
            modifiedAtSource: String? = nil,
            createdAtSource: String? = nil,
            isHidden: Bool = false,
            isPackage: Bool = false,
            isInaccessible: Bool = false
        ) {
            self.id = id
            self.parentID = parentID
            self.relativePath = relativePath
            self.name = name
            self.itemKind = itemKind
            self.logicalSizeBytes = logicalSizeBytes
            self.allocatedSizeBytes = allocatedSizeBytes
            self.modifiedAtSource = modifiedAtSource
            self.createdAtSource = createdAtSource
            self.isHidden = isHidden
            self.isPackage = isPackage
            self.isInaccessible = isInaccessible
        }
    }

    static func root(id: Int64 = 1, name: String = "Root") -> SeedEntry {
        SeedEntry(id: id, parentID: nil, relativePath: "", name: name, itemKind: .directory)
    }

    /// Inserts entries in bounded multi-row statements. The root entry is
    /// id 1 with an empty relative path; parents must precede children.
    static func insertEntries(database: CatalogDatabase, snapshotID: SnapshotID, entries: [SeedEntry], chunkSize: Int = 500) throws {
        for start in stride(from: 0, to: entries.count, by: chunkSize) {
            let chunk = Array(entries[start..<min(start + chunkSize, entries.count)])
            // Exactly one placeholder per bound value: created_at is written
            // as CURRENT_TIMESTAMP in SQL, so the 19 bindings below line up
            // one-to-one with the 19 placeholders.
            let placeholders = chunk.map { _ in "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)" }.joined(separator: ", ")
            var bindings: [DatabaseValue] = []
            bindings.reserveCapacity(chunk.count * 19)
            for entry in chunk {
                let preserving = PathIdentity.casePreserving(entry.relativePath)
                let folded = PathIdentity.caseFold(entry.relativePath)
                let namePreserving = PathIdentity.casePreserving(entry.name)
                let nameFolded = PathIdentity.caseFold(entry.name)
                let fileExtension: DatabaseValue = {
                    guard let dot = entry.name.lastIndex(of: "."), dot != entry.name.startIndex else { return .null }
                    return .text(String(entry.name[entry.name.index(after: dot)...]))
                }()
                bindings += [
                    .integer(entry.id), .integer(snapshotID.rawValue),
                    entry.parentID.map(DatabaseValue.integer) ?? .null,
                    .text(entry.relativePath), .text(preserving), .text(folded),
                    .text(entry.name), .text(namePreserving), .text(nameFolded),
                    fileExtension,
                    .text(entry.itemKind.rawValue),
                    entry.logicalSizeBytes.map(DatabaseValue.integer) ?? .null,
                    entry.allocatedSizeBytes.map(DatabaseValue.integer) ?? .null,
                    entry.createdAtSource.map(DatabaseValue.text) ?? .null,
                    entry.modifiedAtSource.map(DatabaseValue.text) ?? .null,
                    .integer(entry.isHidden ? 1 : 0),
                    .integer(entry.isPackage ? 1 : 0),
                    .integer(entry.isInaccessible ? 1 : 0),
                    .text(folded)
                ]
            }
            try database.execute(
                """
                INSERT INTO entries (
                    id, snapshot_id, parent_id, relative_path, case_preserving_path,
                    case_folded_path, name, case_preserving_name, case_folded_name,
                    file_extension, item_type, logical_size_bytes, allocated_size_bytes,
                    created_at_source, modified_at_source, is_hidden, is_package,
                    is_inaccessible, sort_key, created_at
                ) VALUES \(placeholders)
                """,
                bindings: bindings
            )
        }
    }

    /// Transitions the snapshot to `complete` through the repository, which
    /// exercises the same root/normalization guards as production capture.
    static func complete(database: CatalogDatabase, snapshotID: SnapshotID) throws {
        try SnapshotRepository(database: database).complete(snapshotID)
    }

    /// A deterministic directory tree: `directoryCount` directories named
    /// `d<4>` each containing `filesPerDirectory` files named `f<5>.bin`.
    /// Sizes follow a deterministic formula so two seeds of the same shape
    /// are identical.
    static func treeEntries(
        directoryCount: Int,
        filesPerDirectory: Int,
        firstID: Int64 = 1,
        rootName: String = "Root",
        sizeOfFile: (Int, Int) -> Int64,
        modifiedAt: String? = nil,
        hiddenDirs: Set<String> = [],
        modifiedFiles: Set<String> = [],
        removedFiles: Set<String> = []
    ) -> (entries: [SeedEntry], rootID: Int64, directoryIDs: [String: Int64], fileIDs: [String: Int64]) {
        var entries: [SeedEntry] = []
        var directoryIDs: [String: Int64] = [:]
        var fileIDs: [String: Int64] = [:]
        var nextID = firstID
        let rootID = nextID
        entries.append(root(id: rootID, name: rootName))
        nextID += 1

        for dirIndex in 0..<directoryCount {
            let dirName = String(format: "d%04d", dirIndex)
            let dirPath = dirName
            let dirID = nextID
            nextID += 1
            directoryIDs[dirPath] = dirID
            entries.append(SeedEntry(
                id: dirID, parentID: rootID, relativePath: dirPath, name: dirName,
                itemKind: .directory, isHidden: hiddenDirs.contains(dirName)
            ))
            for fileIndex in 0..<filesPerDirectory {
                let fileName = String(format: "f%05d.bin", fileIndex)
                let filePath = "\(dirPath)/\(fileName)"
                let fileID = nextID
                nextID += 1
                fileIDs[filePath] = fileID
                guard !removedFiles.contains(filePath) else { continue }
                entries.append(SeedEntry(
                    id: fileID, parentID: dirID, relativePath: filePath, name: fileName,
                    itemKind: .file,
                    logicalSizeBytes: sizeOfFile(dirIndex, fileIndex),
                    allocatedSizeBytes: sizeOfFile(dirIndex, fileIndex),
                    modifiedAtSource: modifiedAt
                ))
            }
        }
        return (entries, rootID, directoryIDs, fileIDs)
    }

    /// Seeds one tree into a snapshot in one pass and completes it.
    static func seedTree(
        database: CatalogDatabase,
        snapshotID: SnapshotID,
        directoryCount: Int,
        filesPerDirectory: Int,
        sizeOfFile: @escaping (Int, Int) -> Int64,
        modifiedAt: String? = nil
    ) throws {
        let built = treeEntries(
            directoryCount: directoryCount,
            filesPerDirectory: filesPerDirectory,
            sizeOfFile: sizeOfFile,
            modifiedAt: modifiedAt
        )
        try insertEntries(database: database, snapshotID: snapshotID, entries: built.entries)
        try complete(database: database, snapshotID: snapshotID)
    }
}

/// Deterministic size formula shared by scale fixtures.
func syntheticSize(_ dirIndex: Int, _ fileIndex: Int) -> Int64 {
    Int64((dirIndex * 7919 + fileIndex * 104729) % 10_000_000)
}

/// Read-only assertions about entry data, so a comparison test can prove the
/// engine never mutates snapshot entries.
enum EntrySnapshotProbe {
    static func contentFingerprint(database: CatalogDatabase, snapshotID: SnapshotID) throws -> String {
        let rows = try database.query(
            "SELECT id, relative_path, name, item_type, logical_size_bytes, is_hidden, is_inaccessible FROM entries WHERE snapshot_id = ? ORDER BY id",
            bindings: [.integer(snapshotID.rawValue)]
        )
        return rows.map { row in
            "\(row["id"]?.int64Value ?? 0)|\(row["relative_path"]?.stringValue ?? "")|\(row["name"]?.stringValue ?? "")|\(row["item_type"]?.stringValue ?? "")|\(row["logical_size_bytes"]?.int64Value ?? -1)|\(row["is_hidden"]?.int64Value ?? -1)|\(row["is_inaccessible"]?.int64Value ?? -1)"
        }.joined(separator: "\n")
    }

    static func snapshotFingerprint(database: CatalogDatabase, snapshotID: SnapshotID) throws -> String {
        let rows = try database.query(
            "SELECT status, total_files, total_folders, total_logical_bytes, warning_count FROM snapshots WHERE id = ?",
            bindings: [.integer(snapshotID.rawValue)]
        )
        return rows.map { row in
            "\(row["status"]?.stringValue ?? "")|\(row["total_files"]?.int64Value ?? -1)|\(row["total_folders"]?.int64Value ?? -1)|\(row["total_logical_bytes"]?.int64Value ?? -1)|\(row["warning_count"]?.int64Value ?? -1)"
        }.joined(separator: "\n")
    }

    static func classificationRowCount(database: CatalogDatabase) throws -> Int64 {
        try database.scalar("SELECT COUNT(*) FROM entry_classifications")?.int64Value ?? -1
    }
}

/// Turns a one-shot progress callback into a cancel trigger: the token is
/// cancelled on the first progress tick past `threshold`.
func cancelToken(afterThreshold threshold: Int64) -> (CaptureCancellationToken, (ComparisonProgress) -> Void) {
    let token = CaptureCancellationToken()
    var didCancel = false
    let onProgress: (ComparisonProgress) -> Void = { progress in
        if !didCancel, progress.processedEntries >= threshold {
            didCancel = true
            token.cancel()
        }
    }
    return (token, onProgress)
}
