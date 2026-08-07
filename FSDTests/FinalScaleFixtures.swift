import Foundation
@testable import FSD

/// Final-scale (one-million-entry class) synthetic fixtures for the Milestone
/// 5 gates. Everything is generated directly into SQLite — no physical files,
/// no source access — through the same schema/triggers the scanner uses, so
/// the production invariants are exercised without a filesystem.
///
/// Generation is memory-bounded by construction: entries are built and
/// inserted per directory (1,000 files at a time), never as one whole-tree
/// array, and each batch commits in its own transaction. The full tree is
/// never loaded into UI or application memory by any later operation.
enum FinalScaleFixtures {
    /// Inserts one directory's worth of entries in a single transaction.
    /// Chunks stay under SQLite's bound limit (19 bindings × 1,500 rows).
    static func insertBatch(
        database: CatalogDatabase,
        snapshotID: SnapshotID,
        entries: [SyntheticSnapshot.SeedEntry]
    ) throws {
        try database.transaction {
            try SyntheticSnapshot.insertEntries(database: database, snapshotID: snapshotID, entries: entries, chunkSize: 1500)
        }
    }
}

// MARK: - One-million-entry snapshot catalog (Part 2 gate)

enum M5SnapshotCatalog {
    static let directoryCount = 1_000
    static let filesPerDirectory = 1_000          // 1,000 × 1,000 = 1,000,000 files
    static let deepLevels = 40                    // 40-level deep branch
    static let deepFiles = 1_000                  // files in the deepest level
    static let hiddenFileCount = 100

    /// root + dirs + files + deep chain (dirs + leaf files + deep files) +
    /// hidden directory (dir + files).
    static var expectedEntryCount: Int64 {
        Int64(
            1
            + directoryCount + directoryCount * filesPerDirectory
            + deepLevels + deepLevels + deepFiles
            + 1 + hiddenFileCount
        )
    }

    struct Result {
        let snapshotID: SnapshotID
        let rootID: Int64
        let insertSeconds: Double
        let entryCount: Int64
    }

    /// Builds the 1,002,182-entry catalog: 1,000 directories of 1,000 files,
    /// a `deep00…deep39` chain (each level holding one `leaf.dat`, the
    /// deepest holding 1,000 `deepfile%05d.bin`), and a `zhidden` directory
    /// of 100 hidden files for hidden-filter search probes.
    static func populate(database: CatalogDatabase, volumeID: Int64 = 9001) throws -> Result {
        let started = Date()
        let repository = SnapshotRepository(database: database)
        try repository.createVolume(id: volumeID, displayName: "Synthetic Million Volume")
        let snapshotID = try repository.createSnapshot(
            volumeID: volumeID, sessionNumber: 1, scanRootName: "Million"
        )
        var nextID: Int64 = 1
        let rootID = nextID
        var batch: [SyntheticSnapshot.SeedEntry] = []
        batch.append(SyntheticSnapshot.root(id: rootID, name: "Million"))
        nextID += 1

        // 1,000 directories under the root.
        let directories = (0..<Self.directoryCount).map { index -> SyntheticSnapshot.SeedEntry in
            let name = String(format: "d%04d", index)
            let id = nextID
            nextID += 1
            return SyntheticSnapshot.SeedEntry(id: id, parentID: rootID, relativePath: name, name: name, itemKind: .directory)
        }
        batch.append(contentsOf: directories)
        try FinalScaleFixtures.insertBatch(database: database, snapshotID: snapshotID, entries: batch)
        batch.removeAll(keepingCapacity: true)

        // 1,000 files per directory.
        for dirIndex in 0..<Self.directoryCount {
            let dirName = String(format: "d%04d", dirIndex)
            let dirID = Int64(2 + dirIndex) // deterministic: ids 2…1,001
            let fileEntries = (0..<Self.filesPerDirectory).map { fileIndex -> SyntheticSnapshot.SeedEntry in
                let name = String(format: "f%05d.bin", fileIndex)
                let id = nextID
                nextID += 1
                return SyntheticSnapshot.SeedEntry(
                    id: id, parentID: dirID, relativePath: "\(dirName)/\(name)", name: name,
                    logicalSizeBytes: syntheticSize(dirIndex, fileIndex),
                    allocatedSizeBytes: syntheticSize(dirIndex, fileIndex)
                )
            }
            try FinalScaleFixtures.insertBatch(database: database, snapshotID: snapshotID, entries: fileEntries)
        }

        // Deep branch: deep00 (under root) → deep01 → … → deep39. Each level
        // holds one `leaf.dat`; the deepest level holds `deepFiles` files.
        var previousDeepID = rootID
        for level in 0..<Self.deepLevels {
            let name = String(format: "deep%02d", level)
            let id = nextID
            nextID += 1
            let dirEntry = SyntheticSnapshot.SeedEntry(
                id: id, parentID: previousDeepID,
                relativePath: level == 0 ? name : "\(deepPath(levels: level))\(name)",
                name: name, itemKind: .directory
            )
            var levelEntries = [dirEntry]
            levelEntries.append(SyntheticSnapshot.SeedEntry(
                id: nextID, parentID: id,
                relativePath: dirEntry.relativePath + "/leaf.dat",
                name: "leaf.dat", logicalSizeBytes: 128, allocatedSizeBytes: 128
            ))
            nextID += 1
            if level == Self.deepLevels - 1 {
                for fileIndex in 0..<Self.deepFiles {
                    let fileName = String(format: "deepfile%05d.bin", fileIndex)
                    levelEntries.append(SyntheticSnapshot.SeedEntry(
                        id: nextID, parentID: id,
                        relativePath: dirEntry.relativePath + "/\(fileName)",
                        name: fileName, logicalSizeBytes: syntheticSize(level, fileIndex),
                        allocatedSizeBytes: syntheticSize(level, fileIndex)
                    ))
                    nextID += 1
                }
            }
            try FinalScaleFixtures.insertBatch(database: database, snapshotID: snapshotID, entries: levelEntries)
            previousDeepID = id
        }

        // Hidden directory for hidden-filter search probes.
        var hiddenEntries: [SyntheticSnapshot.SeedEntry] = []
        let hiddenDirID = nextID
        nextID += 1
        hiddenEntries.append(SyntheticSnapshot.SeedEntry(
            id: hiddenDirID, parentID: rootID, relativePath: "zhidden", name: "zhidden",
            itemKind: .directory, isHidden: true
        ))
        for index in 0..<Self.hiddenFileCount {
            let name = String(format: "h%04d.dat", index)
            hiddenEntries.append(SyntheticSnapshot.SeedEntry(
                id: nextID, parentID: hiddenDirID, relativePath: "zhidden/\(name)", name: name,
                logicalSizeBytes: 64, allocatedSizeBytes: 64, isHidden: true
            ))
            nextID += 1
        }
        try FinalScaleFixtures.insertBatch(database: database, snapshotID: snapshotID, entries: hiddenEntries)

        let entryCount = try database.scalar(
            "SELECT COUNT(*) FROM entries WHERE snapshot_id = ?",
            bindings: [.integer(snapshotID.rawValue)]
        )?.int64Value ?? -1
        try database.execute(
            """
            UPDATE snapshots SET total_files = ?, total_folders = ?, total_logical_bytes = 0
            WHERE id = ?
            """,
            bindings: [
                .integer(Int64(Self.directoryCount * Self.filesPerDirectory + Self.deepLevels + Self.deepFiles + Self.hiddenFileCount)),
                .integer(Int64(Self.directoryCount + Self.deepLevels + 1)),
                .integer(snapshotID.rawValue)
            ]
        )
        try repository.complete(snapshotID)
        return Result(
            snapshotID: snapshotID, rootID: rootID,
            insertSeconds: Date().timeIntervalSince(started), entryCount: entryCount
        )
    }

    /// `deep00/deep01/…/deep<level-1>/` — the prefix holding a level's path.
    private static func deepPath(levels: Int) -> String {
        (0..<levels).map { String(format: "deep%02d", $0) }.joined(separator: "/") + "/"
    }
}

// MARK: - One-million-class comparison pair (Part 3 gate)

enum M5ComparisonPair {
    static let directoryCount = 1_000
    static let filesPerDirectory = 1_000
    static let modifiedFileCount = 1_000
    static let oneSidedBranchFileCount = 1_000
    static let inaccessibleFileCount = 100
    static let collisionPairCount = 500
    static let ignoredFileCount = 100

    struct Result {
        let leftID: SnapshotID
        let rightID: SnapshotID
        let leftCount: Int64
        let rightCount: Int64
        let insertSeconds: Double

        // Canonical expected outcomes for the Fast Metadata profile on this
        // exact fixture.
        let expectedMatched: Int64
        let expectedChanged: Int64
        let expectedAdded: Int64
        let expectedRemoved: Int64
        let expectedUncertain: Int64
        let expectedIgnored: Int64
        let expectedCollisionGroups: Int64
        let expectedCollisionMembers: Int64

        var expectedTotal: Int64 {
            expectedMatched + expectedChanged + expectedAdded + expectedRemoved + expectedUncertain + expectedIgnored
        }
    }

    /// Two ~1,003,xxx-entry snapshots, both case-insensitive (so the engine
    /// uses the case-folded identity key, ADR-010), with deterministic
    /// composition:
    ///
    /// * predominantly matched: root + 1,000 dirs + 999,000 unchanged files;
    /// * 1,000 modified files (size +1 in `d0000`);
    /// * `zadded` branch only on the right (1,001 added);
    /// * `zremoved` branch only on the left (1,001 removed);
    /// * `zuncertain` branch only on the right, marked inaccessible
    ///   (101 uncertain);
    /// * 500 case-fold collision pairs in `zcollide` on both sides
    ///   (500 uncertain groups, 2,000 members, never paired);
    /// * 100 `._*` service files per side in `zignore` (200 ignored).
    static func populate(database: CatalogDatabase) throws -> Result {
        let started = Date()
        let leftID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 11, session: 1, sensitivity: .insensitive)
        let rightID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 11, session: 2, sensitivity: .insensitive)

        var leftNext: Int64 = 1
        var rightNext: Int64 = 1_100_000

        func seedBaseSide(
            snapshotID: SnapshotID,
            root: SyntheticSnapshot.SeedEntry,
            dirs: [SyntheticSnapshot.SeedEntry],
            idState: inout Int64,
            sizeOffset: (Int, Int) -> Int64
        ) throws {
            try FinalScaleFixtures.insertBatch(database: database, snapshotID: snapshotID, entries: [root] + dirs)
            for dirIndex in 0..<Self.directoryCount {
                let dirName = String(format: "d%04d", dirIndex)
                let dirID = dirs[dirIndex].id
                let fileEntries = (0..<Self.filesPerDirectory).map { fileIndex -> SyntheticSnapshot.SeedEntry in
                    let name = String(format: "f%05d.bin", fileIndex)
                    let id = idState
                    idState += 1
                    let size = syntheticSize(dirIndex, fileIndex) + sizeOffset(dirIndex, fileIndex)
                    return SyntheticSnapshot.SeedEntry(
                        id: id, parentID: dirID, relativePath: "\(dirName)/\(name)", name: name,
                        logicalSizeBytes: size, allocatedSizeBytes: size
                    )
                }
                try FinalScaleFixtures.insertBatch(database: database, snapshotID: snapshotID, entries: fileEntries)
            }
        }

        // Left side.
        let leftRootID = leftNext
        leftNext += 1
        var leftDirs: [SyntheticSnapshot.SeedEntry] = []
        for index in 0..<Self.directoryCount {
            let name = String(format: "d%04d", index)
            let id = leftNext
            leftNext += 1
            leftDirs.append(SyntheticSnapshot.SeedEntry(id: id, parentID: leftRootID, relativePath: name, name: name, itemKind: .directory))
        }
        try seedBaseSide(snapshotID: leftID, root: SyntheticSnapshot.root(id: leftRootID, name: "Root"), dirs: leftDirs, idState: &leftNext) { _, _ in 0 }

        // Left-only removed branch.
        let removedDirID = leftNext
        leftNext += 1
        var removedEntries: [SyntheticSnapshot.SeedEntry] = [SyntheticSnapshot.SeedEntry(
            id: removedDirID, parentID: leftRootID, relativePath: "zremoved", name: "zremoved", itemKind: .directory
        )]
        for index in 0..<Self.oneSidedBranchFileCount {
            let name = String(format: "f%05d.bin", index)
            removedEntries.append(SyntheticSnapshot.SeedEntry(
                id: leftNext, parentID: removedDirID, relativePath: "zremoved/\(name)", name: name,
                logicalSizeBytes: syntheticSize(98, index), allocatedSizeBytes: syntheticSize(98, index)
            ))
            leftNext += 1
        }
        try FinalScaleFixtures.insertBatch(database: database, snapshotID: leftID, entries: removedEntries)

        // Left collision pairs.
        let leftCollideDirID = leftNext
        leftNext += 1
        var collideEntries: [SyntheticSnapshot.SeedEntry] = [SyntheticSnapshot.SeedEntry(
            id: leftCollideDirID, parentID: leftRootID, relativePath: "zcollide", name: "zcollide", itemKind: .directory
        )]
        for index in 0..<Self.collisionPairCount {
            let lower = String(format: "coll%04d.txt", index)
            let upper = String(format: "COLL%04d.TXT", index)
            collideEntries.append(SyntheticSnapshot.SeedEntry(
                id: leftNext, parentID: leftCollideDirID, relativePath: "zcollide/\(lower)", name: lower,
                logicalSizeBytes: 1024 + Int64(index), allocatedSizeBytes: 1024 + Int64(index)
            ))
            leftNext += 1
            collideEntries.append(SyntheticSnapshot.SeedEntry(
                id: leftNext, parentID: leftCollideDirID, relativePath: "zcollide/\(upper)", name: upper,
                logicalSizeBytes: 1024 + Int64(index), allocatedSizeBytes: 1024 + Int64(index)
            ))
            leftNext += 1
        }
        // Left ignored service files.
        let leftIgnoreDirID = leftNext
        leftNext += 1
        var leftIgnoreEntries: [SyntheticSnapshot.SeedEntry] = [SyntheticSnapshot.SeedEntry(
            id: leftIgnoreDirID, parentID: leftRootID, relativePath: "zignore", name: "zignore", itemKind: .directory
        )]
        for index in 0..<Self.ignoredFileCount {
            let name = String(format: "._ignored%04d", index)
            leftIgnoreEntries.append(SyntheticSnapshot.SeedEntry(
                id: leftNext, parentID: leftIgnoreDirID, relativePath: "zignore/\(name)", name: name,
                logicalSizeBytes: 8, allocatedSizeBytes: 8
            ))
            leftNext += 1
        }
        try FinalScaleFixtures.insertBatch(database: database, snapshotID: leftID, entries: collideEntries + leftIgnoreEntries)

        // Right side: mirrors the left base, 1,000 files in d0000 modified.
        let rightRootID = rightNext
        rightNext += 1
        var rightDirs: [SyntheticSnapshot.SeedEntry] = []
        for index in 0..<Self.directoryCount {
            let name = String(format: "d%04d", index)
            let id = rightNext
            rightNext += 1
            rightDirs.append(SyntheticSnapshot.SeedEntry(id: id, parentID: rightRootID, relativePath: name, name: name, itemKind: .directory))
        }
        try seedBaseSide(snapshotID: rightID, root: SyntheticSnapshot.root(id: rightRootID, name: "Root"), dirs: rightDirs, idState: &rightNext) { dirIndex, fileIndex in
            dirIndex == 0 && fileIndex < Self.modifiedFileCount ? 1 : 0
        }

        // Right-only added branch.
        let addedDirID = rightNext
        rightNext += 1
        var addedEntries: [SyntheticSnapshot.SeedEntry] = [SyntheticSnapshot.SeedEntry(
            id: addedDirID, parentID: rightRootID, relativePath: "zadded", name: "zadded", itemKind: .directory
        )]
        for index in 0..<Self.oneSidedBranchFileCount {
            let name = String(format: "f%05d.bin", index)
            addedEntries.append(SyntheticSnapshot.SeedEntry(
                id: rightNext, parentID: addedDirID, relativePath: "zadded/\(name)", name: name,
                logicalSizeBytes: syntheticSize(99, index), allocatedSizeBytes: syntheticSize(99, index)
            ))
            rightNext += 1
        }
        try FinalScaleFixtures.insertBatch(database: database, snapshotID: rightID, entries: addedEntries)

        // Right collision pairs (same names, different ids).
        let rightCollideDirID = rightNext
        rightNext += 1
        var rightCollideEntries: [SyntheticSnapshot.SeedEntry] = [SyntheticSnapshot.SeedEntry(
            id: rightCollideDirID, parentID: rightRootID, relativePath: "zcollide", name: "zcollide", itemKind: .directory
        )]
        for index in 0..<Self.collisionPairCount {
            let lower = String(format: "coll%04d.txt", index)
            let upper = String(format: "COLL%04d.TXT", index)
            rightCollideEntries.append(SyntheticSnapshot.SeedEntry(
                id: rightNext, parentID: rightCollideDirID, relativePath: "zcollide/\(lower)", name: lower,
                logicalSizeBytes: 1024 + Int64(index), allocatedSizeBytes: 1024 + Int64(index)
            ))
            rightNext += 1
            rightCollideEntries.append(SyntheticSnapshot.SeedEntry(
                id: rightNext, parentID: rightCollideDirID, relativePath: "zcollide/\(upper)", name: upper,
                logicalSizeBytes: 1024 + Int64(index), allocatedSizeBytes: 1024 + Int64(index)
            ))
            rightNext += 1
        }
        // Right ignored service files.
        let rightIgnoreDirID = rightNext
        rightNext += 1
        var rightIgnoreEntries: [SyntheticSnapshot.SeedEntry] = [SyntheticSnapshot.SeedEntry(
            id: rightIgnoreDirID, parentID: rightRootID, relativePath: "zignore", name: "zignore", itemKind: .directory
        )]
        for index in 0..<Self.ignoredFileCount {
            let name = String(format: "._ignored%04d", index)
            rightIgnoreEntries.append(SyntheticSnapshot.SeedEntry(
                id: rightNext, parentID: rightIgnoreDirID, relativePath: "zignore/\(name)", name: name,
                logicalSizeBytes: 8, allocatedSizeBytes: 8
            ))
            rightNext += 1
        }
        // Right-only inaccessible branch.
        let uncertainDirID = rightNext
        rightNext += 1
        var uncertainEntries: [SyntheticSnapshot.SeedEntry] = [SyntheticSnapshot.SeedEntry(
            id: uncertainDirID, parentID: rightRootID, relativePath: "zuncertain", name: "zuncertain",
            itemKind: .directory, isInaccessible: true
        )]
        for index in 0..<Self.inaccessibleFileCount {
            let name = String(format: "u%04d.bin", index)
            uncertainEntries.append(SyntheticSnapshot.SeedEntry(
                id: rightNext, parentID: uncertainDirID, relativePath: "zuncertain/\(name)", name: name,
                logicalSizeBytes: 32, allocatedSizeBytes: 32, isInaccessible: true
            ))
            rightNext += 1
        }
        try FinalScaleFixtures.insertBatch(database: database, snapshotID: rightID, entries: rightCollideEntries + rightIgnoreEntries + uncertainEntries)

        let leftCount = Int64(leftNext - 1)
        let rightCount = Int64(rightNext - 1_100_000)
        try SyntheticSnapshot.complete(database: database, snapshotID: leftID)
        try SyntheticSnapshot.complete(database: database, snapshotID: rightID)

        return Result(
            leftID: leftID, rightID: rightID, leftCount: leftCount, rightCount: rightCount,
            insertSeconds: Date().timeIntervalSince(started),
            expectedMatched: 1_000_003,
            expectedChanged: 1_000,
            expectedAdded: 1_001,
            expectedRemoved: 1_001,
            expectedUncertain: 601,
            expectedIgnored: 200,
            expectedCollisionGroups: 500,
            expectedCollisionMembers: 2_000
        )
    }
}

// MARK: - Pathological equal-key collision pair (Part 4 bound, KI-019)

/// A pair of snapshots where one key owns 150,000 members per side: 150,000
/// distinct paths in `zcoll/` that differ only in the case of a 20-character
/// ASCII name, so every one of them folds to the same comparison key. This is
/// the pathological equal-key condition the engine must refuse as a typed
/// failure instead of exhausting memory.
enum M5PathologicalPair {
    static let memberCount = 150_000
    static let caseVariantLength = 20

    static func populate(database: CatalogDatabase) throws -> (leftID: SnapshotID, rightID: SnapshotID) {
        let leftID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 21, session: 1, sensitivity: .insensitive)
        let rightID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 21, session: 2, sensitivity: .insensitive)

        var nextLeft: Int64 = 1
        var nextRight: Int64 = 1_000_000
        func seedSide(snapshotID: SnapshotID, idState: inout Int64) throws {
            let rootID = idState
            idState += 1
            let dirID = idState
            idState += 1
            try FinalScaleFixtures.insertBatch(database: database, snapshotID: snapshotID, entries: [
                SyntheticSnapshot.root(id: rootID, name: "Root"),
                SyntheticSnapshot.SeedEntry(id: dirID, parentID: rootID, relativePath: "zcoll", name: "zcoll", itemKind: .directory)
            ])
            // Chunked so fixture generation itself stays memory-bounded.
            for chunkStart in stride(from: 0, to: Self.memberCount, by: 10_000) {
                let chunkEnd = min(chunkStart + 10_000, Self.memberCount)
                var chunk: [SyntheticSnapshot.SeedEntry] = []
                chunk.reserveCapacity(chunkEnd - chunkStart)
                for index in chunkStart..<chunkEnd {
                    let name = caseVariantName(index)
                    chunk.append(SyntheticSnapshot.SeedEntry(
                        id: idState, parentID: dirID, relativePath: "zcoll/\(name)", name: name,
                        logicalSizeBytes: 1, allocatedSizeBytes: 1
                    ))
                    idState += 1
                }
                try FinalScaleFixtures.insertBatch(database: database, snapshotID: snapshotID, entries: chunk)
            }
        }
        try seedSide(snapshotID: leftID, idState: &nextLeft)
        try seedSide(snapshotID: rightID, idState: &nextRight)
        try SyntheticSnapshot.complete(database: database, snapshotID: leftID)
        try SyntheticSnapshot.complete(database: database, snapshotID: rightID)
        return (leftID, rightID)
    }

    /// 20 ASCII characters chosen from the index's bits: every name differs
    /// only by case, so all fold to the same key while remaining distinct.
    static func caseVariantName(_ index: Int) -> String {
        var name = ""
        var value = index
        for _ in 0..<caseVariantLength {
            name.append(value & 1 == 0 ? "a" : "A")
            value >>= 1
        }
        return name + ".txt"
    }
}
