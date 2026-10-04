import XCTest
@testable import FSD

/// Comparison outcome semantics on small, fully controlled synthetic trees:
/// matched / added / removed / changed, field-level differences, profile
/// field selection, deterministic ordering, and the metadata-only boundary.
final class ComparisonSemanticsTests: XCTestCase {
    private var directory: URL!
    private var database: CatalogDatabase!
    private var service: ComparisonService!
    private var results: ComparisonResultRepository!

    private var leftSnapshot: SnapshotID!
    private var rightSnapshot: SnapshotID!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-Compare-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        database = try CatalogDatabase(
            url: directory.appendingPathComponent("catalog.sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
        service = ComparisonService(database: database)
        results = ComparisonResultRepository(database: database)
    }

    override func tearDownWithError() throws {
        results = nil
        service = nil
        database?.close()
        database = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        leftSnapshot = nil
        rightSnapshot = nil
    }

    // MARK: - Fixtures

    /// Two tiny trees with known outcomes:
    ///
    /// ```text
    /// left                       right
    /// same.txt      (1 KB)       same.txt      (1 KB)          → matched
    /// grown.bin     (10 B)       grown.bin     (99 B)          → changed (logical size)
    /// gone.txt      (1 B)        –                             → removed
    /// –                            fresh.txt    (2 B)          → added
    /// typed.mov     (file)       typed.mov     (directory)    → changed (item type + size)
    /// date.txt      (t=1000)     date.txt      (t=1003)        → matched under Fast Metadata
    /// ```
    ///
    /// Entry ids are table-global unique, so each side gets its own range:
    /// left root 100, entries 101+; right root 200, entries 201+.
    private func seedKnownPair() throws {
        let leftID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 1, sensitivity: .sensitive)
        let rightID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 2, sensitivity: .sensitive)

        func entries(_ rootID: Int64, paths: [(String, FilesystemItemKind, Int64?, Int64?, String?)]) -> [SyntheticSnapshot.SeedEntry] {
            paths.enumerated().map { index, item in
                SyntheticSnapshot.SeedEntry(
                    id: rootID + Int64(index + 1),
                    parentID: rootID,
                    relativePath: item.0,
                    name: item.0,
                    itemKind: item.1,
                    logicalSizeBytes: item.2,
                    allocatedSizeBytes: item.3,
                    modifiedAtSource: item.4
                )
            }
        }

        let leftRoot = SyntheticSnapshot.root(id: 100, name: "Root")
        let rightRoot = SyntheticSnapshot.root(id: 200, name: "Root")
        let leftEntries = [leftRoot] + entries(100, paths: [
            ("same.txt", .file, 1024, 4096, nil),
            ("grown.bin", .file, 10, 10, nil),
            ("gone.txt", .file, 1, 1, nil),
            ("typed.mov", .file, 500, 500, nil),
            ("date.txt", .file, 7, 7, "1000")
        ])
        let rightEntries = [rightRoot] + entries(200, paths: [
            ("same.txt", .file, 1024, 4096, nil),
            ("grown.bin", .file, 99, 99, nil),
            ("fresh.txt", .file, 2, 2, nil),
            ("typed.mov", .directory, 501, 501, nil),
            ("date.txt", .file, 7, 7, "1003")
        ])
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: leftID, entries: leftEntries)
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: rightID, entries: rightEntries)
        try SyntheticSnapshot.complete(database: database, snapshotID: leftID)
        try SyntheticSnapshot.complete(database: database, snapshotID: rightID)
        leftSnapshot = leftID
        rightSnapshot = rightID
    }

    private func compare(_ profileID: Int64 = ComparisonProfileRepository.fastMetadataProfileID) throws -> ComparisonRecord {
        try service.snapshotToSnapshot(leftSnapshotID: leftSnapshot, rightSnapshotID: rightSnapshot, profileID: profileID)
    }

    private func rows(_ comparison: ComparisonRecord) throws -> [ComparisonResultRow] {
        try results.results(comparisonID: comparison.id, filter: .all, limit: 1000).rows
    }

    // MARK: - Core outcomes

    func testUnchangedEntryIsMatchedWithNoFieldDifferences() throws {
        try seedKnownPair()
        let comparison = try compare()
        XCTAssertEqual(comparison.status, .complete)
        XCTAssertEqual(comparison.matchedCount, 3, "same.txt, typed root? no — same.txt, date.txt(not under fast), and the root entry")

        let matched = try rows(comparison).filter { $0.resultType == .matched }
        XCTAssertTrue(matched.contains { $0.resultPath == "same.txt" })
        XCTAssertEqual(matched.first { $0.resultPath == "same.txt" }?.differenceFlags, 0)
        XCTAssertTrue(matched.contains { $0.resultPath == "" }, "root entries match")
    }

    func testClassificationMetadataCannotChangeComparisonOutcome() throws {
        try seedKnownPair()
        let leftEntryID = try XCTUnwrap(try database.scalar(
            "SELECT id FROM entries WHERE snapshot_id = ? AND relative_path = 'same.txt'",
            bindings: [.integer(leftSnapshot.rawValue)]
        )?.int64Value)
        let rightEntryID = try XCTUnwrap(try database.scalar(
            "SELECT id FROM entries WHERE snapshot_id = ? AND relative_path = 'same.txt'",
            bindings: [.integer(rightSnapshot.rawValue)]
        )?.int64Value)
        let classifications = EntryClassificationRepository(database: database)
        _ = try classifications.append(EntryClassificationInput(
            entryID: leftEntryID, classificationRunID: "left-run", detectedType: "text/plain", confidence: 0.10, providerIdentifier: "comparison-fixture-left"
        ))
        _ = try classifications.append(EntryClassificationInput(
            entryID: rightEntryID, classificationRunID: "right-run", detectedType: "application/octet-stream", confidence: 0.99, providerIdentifier: "comparison-fixture-right"
        ))

        let comparison = try compare()
        let same = try XCTUnwrap(try rows(comparison).first { $0.resultPath == "same.txt" })
        XCTAssertEqual(same.resultType, .matched)
        XCTAssertEqual(same.differenceFlags, 0)
        XCTAssertEqual(comparison.matchedCount, 3)
        XCTAssertEqual(comparison.changedCount, 2)
    }

    func testAddedAndRemovedEntriesAreClassifiedExactly() throws {
        try seedKnownPair()
        let comparison = try compare()
        let all = try rows(comparison)

        XCTAssertTrue(all.contains { $0.resultType == .added && $0.resultPath == "fresh.txt" })
        XCTAssertTrue(all.contains { $0.resultType == .removed && $0.resultPath == "gone.txt" })
        XCTAssertEqual(all.filter { $0.resultType == .added }.count, 1)
        XCTAssertEqual(all.filter { $0.resultType == .removed }.count, 1)
        XCTAssertEqual(comparison.addedCount, 1)
        XCTAssertEqual(comparison.removedCount, 1)
    }

    func testOneFieldModificationProducesTheExactFieldBit() throws {
        try seedKnownPair()
        let comparison = try compare()
        let changed = try rows(comparison).filter { $0.resultType == .changed }
        XCTAssertTrue(changed.contains { $0.resultPath == "grown.bin" })
        let grown = changed.first { $0.resultPath == "grown.bin" }
        XCTAssertEqual(grown?.differenceFlags, ComparisonField.logicalSize.flagBit)
        XCTAssertEqual(grown?.differenceFields, [.logicalSize])
    }

    func testMultiFieldModificationProducesAllFieldBits() throws {
        try seedKnownPair()
        let comparison = try compare()
        let typed = try rows(comparison).first { $0.resultType == .changed && $0.resultPath == "typed.mov" }
        XCTAssertNotNil(typed)
        XCTAssertEqual(Set(typed!.differenceFields), [.itemType, .logicalSize])
        XCTAssertEqual(ComparisonField.fields(for: typed!.differenceFlags).count, 2)
    }

    func testFieldDifferencesDecodeToLeftAndRightValues() throws {
        try seedKnownPair()
        let comparison = try compare()
        let grown = try rows(comparison).first { $0.resultPath == "grown.bin" && $0.resultType == .changed }
        let differences = try results.fieldDifferences(for: XCTUnwrap(grown), comparisonID: comparison.id)
        XCTAssertEqual(differences.count, 1)
        XCTAssertEqual(differences[0].field, .logicalSize)
        XCTAssertEqual(differences[0].leftValue, "10")
        XCTAssertEqual(differences[0].rightValue, "99")
        XCTAssertTrue(differences[0].changed)
    }

    // MARK: - Profiles

    func testStructureOnlyProfileIgnoresSizesEntirely() throws {
        try seedKnownPair()
        let comparison = try compare(ComparisonProfileRepository.structureOnlyProfileID)
        let grown = try rows(comparison).first { $0.resultPath == "grown.bin" }
        XCTAssertEqual(grown?.resultType, .matched, "logical size is not compared under Structure Only")
        XCTAssertEqual(grown?.differenceFlags, 0)
    }

    func testAllocatedSizeIsNotComparedByAnyCanonicalProfile() throws {
        let leftID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 1, sensitivity: .sensitive)
        let rightID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 2, sensitivity: .sensitive)
        let leftRoot = SyntheticSnapshot.root(id: 100, name: "Root")
        let rightRoot = SyntheticSnapshot.root(id: 200, name: "Root")
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: leftID, entries: [
            leftRoot,
            SyntheticSnapshot.SeedEntry(id: 101, parentID: 100, relativePath: "sparse.bin", name: "sparse.bin", logicalSizeBytes: 1_000_000, allocatedSizeBytes: 4096)
        ])
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: rightID, entries: [
            rightRoot,
            SyntheticSnapshot.SeedEntry(id: 201, parentID: 200, relativePath: "sparse.bin", name: "sparse.bin", logicalSizeBytes: 1_000_000, allocatedSizeBytes: 1_000_000)
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: leftID)
        try SyntheticSnapshot.complete(database: database, snapshotID: rightID)
        leftSnapshot = leftID
        rightSnapshot = rightID

        let comparison = try compare()
        XCTAssertEqual(comparison.changedCount, 0)
        XCTAssertEqual(try rows(comparison).first { $0.resultPath == "sparse.bin" }?.resultType, .matched,
                       "allocated size differs but no canonical profile compares it (ADR-005)")
    }

    func testTimestampToleranceIsRespectedUnderStrictMetadata() throws {
        let leftID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 1, sensitivity: .sensitive)
        let rightID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 2, sensitivity: .sensitive)
        let leftRoot = SyntheticSnapshot.root(id: 100, name: "Root")
        let rightRoot = SyntheticSnapshot.root(id: 200, name: "Root")
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: leftID, entries: [
            leftRoot,
            SyntheticSnapshot.SeedEntry(id: 101, parentID: 100, relativePath: "a.txt", name: "a.txt", logicalSizeBytes: 1, modifiedAtSource: "1000.0")
        ])
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: rightID, entries: [
            rightRoot,
            SyntheticSnapshot.SeedEntry(id: 201, parentID: 200, relativePath: "a.txt", name: "a.txt", logicalSizeBytes: 1, modifiedAtSource: "1001.5")
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: leftID)
        try SyntheticSnapshot.complete(database: database, snapshotID: rightID)
        leftSnapshot = leftID
        rightSnapshot = rightID

        // Strict Metadata: compare_modified_at = 1 with a 2-second tolerance;
        // a 1.5 s delta is within tolerance → matched.
        let withinTolerance = try compare(ComparisonProfileRepository.strictMetadataProfileID)
        XCTAssertEqual(withinTolerance.changedCount, 0)

        // Fast Metadata ignores timestamps entirely.
        let fast = try compare(ComparisonProfileRepository.fastMetadataProfileID)
        XCTAssertEqual(fast.changedCount, 0)
    }

    func testModifiedTimestampBeyondToleranceIsChangedUnderStrictMetadata() throws {
        let leftID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 1, sensitivity: .sensitive)
        let rightID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 2, sensitivity: .sensitive)
        let leftRoot = SyntheticSnapshot.root(id: 100, name: "Root")
        let rightRoot = SyntheticSnapshot.root(id: 200, name: "Root")
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: leftID, entries: [
            leftRoot,
            SyntheticSnapshot.SeedEntry(id: 101, parentID: 100, relativePath: "a.txt", name: "a.txt", logicalSizeBytes: 1, modifiedAtSource: "1000.0")
        ])
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: rightID, entries: [
            rightRoot,
            SyntheticSnapshot.SeedEntry(id: 201, parentID: 200, relativePath: "a.txt", name: "a.txt", logicalSizeBytes: 1, modifiedAtSource: "1010.0")
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: leftID)
        try SyntheticSnapshot.complete(database: database, snapshotID: rightID)
        leftSnapshot = leftID
        rightSnapshot = rightID

        let comparison = try compare(ComparisonProfileRepository.strictMetadataProfileID)
        let changed = try rows(comparison).first { $0.resultPath == "a.txt" }
        XCTAssertEqual(changed?.resultType, .changed)
        XCTAssertEqual(changed?.differenceFields, [.modifiedAt])
    }

    func testServiceFilesAreIgnoredByFastMetadata() throws {
        let leftID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 1, sensitivity: .sensitive)
        let rightID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 2, sensitivity: .sensitive)
        let leftRoot = SyntheticSnapshot.root(id: 100, name: "Root")
        let rightRoot = SyntheticSnapshot.root(id: 200, name: "Root")
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: leftID, entries: [
            leftRoot,
            SyntheticSnapshot.SeedEntry(id: 101, parentID: 100, relativePath: ".DS_Store", name: ".DS_Store", logicalSizeBytes: 1),
            SyntheticSnapshot.SeedEntry(id: 102, parentID: 100, relativePath: "._Cover.jpg", name: "._Cover.jpg", logicalSizeBytes: 1)
        ])
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: rightID, entries: [
            rightRoot,
            SyntheticSnapshot.SeedEntry(id: 201, parentID: 200, relativePath: ".DS_Store", name: ".DS_Store", logicalSizeBytes: 2)
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: leftID)
        try SyntheticSnapshot.complete(database: database, snapshotID: rightID)
        leftSnapshot = leftID
        rightSnapshot = rightID

        let comparison = try compare()
        XCTAssertEqual(comparison.addedCount, 0, "service files are outside the Fast Metadata universe")
        XCTAssertEqual(comparison.removedCount, 0)
        XCTAssertEqual(comparison.changedCount, 0)
        XCTAssertEqual(comparison.matchedCount, 1, "only the root entries match")

        let all = try rows(comparison)
        XCTAssertEqual(all.filter { $0.resultType == .ignored }.count, 3)
        XCTAssertTrue(all.contains { $0.resultType == .ignored && $0.resultPath == ".DS_Store" })
    }

    func testHiddenItemsAreExcludedByDefaultProfilesAndIncludedByStrict() throws {
        let leftID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 1, sensitivity: .sensitive)
        let rightID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 2, sensitivity: .sensitive)
        let leftRoot = SyntheticSnapshot.root(id: 100, name: "Root")
        let rightRoot = SyntheticSnapshot.root(id: 200, name: "Root")
        let hiddenLeft = SyntheticSnapshot.SeedEntry(id: 101, parentID: 100, relativePath: ".secret", name: ".secret", logicalSizeBytes: 1, isHidden: true)
        let hiddenRight = SyntheticSnapshot.SeedEntry(id: 201, parentID: 200, relativePath: ".secret", name: ".secret", logicalSizeBytes: 2, isHidden: true)
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: leftID, entries: [leftRoot, hiddenLeft])
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: rightID, entries: [rightRoot, hiddenRight])
        try SyntheticSnapshot.complete(database: database, snapshotID: leftID)
        try SyntheticSnapshot.complete(database: database, snapshotID: rightID)
        leftSnapshot = leftID
        rightSnapshot = rightID

        let fast = try compare()
        XCTAssertEqual(fast.changedCount, 0)
        XCTAssertTrue(try rows(fast).contains { $0.resultType == .ignored && $0.resultPath == ".secret" })

        let strict = try compare(ComparisonProfileRepository.strictMetadataProfileID)
        XCTAssertEqual(strict.changedCount, 1, "Strict Metadata compares hidden files, so the size change is a difference")
        XCTAssertTrue(try rows(strict).contains { $0.resultType == .changed && $0.resultPath == ".secret" })
    }

    // MARK: - Inaccessible and uncertain

    func testInaccessibleEntryProducesUncertainOutcome() throws {
        let leftID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 1, sensitivity: .sensitive)
        let rightID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 2, sensitivity: .sensitive)
        let leftRoot = SyntheticSnapshot.root(id: 100, name: "Root")
        let rightRoot = SyntheticSnapshot.root(id: 200, name: "Root")
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: leftID, entries: [
            leftRoot,
            SyntheticSnapshot.SeedEntry(id: 101, parentID: 100, relativePath: "locked.bin", name: "locked.bin", logicalSizeBytes: 10, isInaccessible: true)
        ])
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: rightID, entries: [
            rightRoot,
            SyntheticSnapshot.SeedEntry(id: 201, parentID: 200, relativePath: "locked.bin", name: "locked.bin", logicalSizeBytes: 10, isInaccessible: true)
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: leftID)
        try SyntheticSnapshot.complete(database: database, snapshotID: rightID)
        leftSnapshot = leftID
        rightSnapshot = rightID

        let comparison = try compare()
        XCTAssertEqual(comparison.uncertainCount, 1)
        let uncertain = try rows(comparison).first { $0.resultType == .uncertain }
        XCTAssertNotNil(uncertain)
        XCTAssertEqual(uncertain?.leftEntryID, 101, "the pair is recorded, not arbitrarily dropped")
        XCTAssertEqual(uncertain?.rightEntryID, 201)
    }

    func testInaccessibleOneSidedEntryIsUncertainNeverAdded() throws {
        let leftID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 1, sensitivity: .sensitive)
        let rightID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: 1, session: 2, sensitivity: .sensitive)
        let leftRoot = SyntheticSnapshot.root(id: 100, name: "Root")
        let rightRoot = SyntheticSnapshot.root(id: 200, name: "Root")
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: leftID, entries: [
            leftRoot,
            SyntheticSnapshot.SeedEntry(id: 101, parentID: 100, relativePath: "locked.bin", name: "locked.bin", logicalSizeBytes: 10, isInaccessible: true)
        ])
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: rightID, entries: [rightRoot])
        try SyntheticSnapshot.complete(database: database, snapshotID: leftID)
        try SyntheticSnapshot.complete(database: database, snapshotID: rightID)
        leftSnapshot = leftID
        rightSnapshot = rightID

        let comparison = try compare()
        XCTAssertEqual(comparison.uncertainCount, 1)
        XCTAssertEqual(comparison.addedCount, 0, "an unreadable entry cannot be claimed as added")
        let uncertain = try rows(comparison).first { $0.resultType == .uncertain }
        XCTAssertEqual(uncertain?.leftEntryID, 101)
        XCTAssertNil(uncertain?.rightEntryID)
    }

    // MARK: - Determinism

    func testResultOrderingIsDeterministicAcrossRuns() throws {
        try seedKnownPair()
        let first = try compare()
        let second = try compare()

        let firstRows = try rows(first).map { "\($0.resultPath)|\($0.resultType.rawValue)|\($0.differenceFlags)" }
        let secondRows = try rows(second).map { "\($0.resultPath)|\($0.resultType.rawValue)|\($0.differenceFlags)" }
        XCTAssertEqual(firstRows, secondRows)

        XCTAssertEqual(first.matchedCount, second.matchedCount)
        XCTAssertEqual(first.addedCount, second.addedCount)
        XCTAssertEqual(first.removedCount, second.removedCount)
        XCTAssertEqual(first.changedCount, second.changedCount)
        XCTAssertEqual(first.uncertainCount, second.uncertainCount)
    }

    func testFieldOrderingIsCanonical() throws {
        XCTAssertEqual(
            ComparisonField.allCases.map(\.rawValue),
            ["item_type", "logical_size", "allocated_size", "modified_at", "created_at"]
        )
        // A flags value decodes in canonical field order regardless of the
        // bit positions.
        let combined = ComparisonField.itemType.flagBit | ComparisonField.createdAt.flagBit | ComparisonField.logicalSize.flagBit
        XCTAssertEqual(ComparisonField.fields(for: combined), [.itemType, .logicalSize, .createdAt])
    }

    // MARK: - Metadata-only boundary

    func testComparisonNeverReadsOrWritesClassificationRows() throws {
        try seedKnownPair()
        _ = try compare()
        XCTAssertEqual(try EntrySnapshotProbe.classificationRowCount(database: database), 0)
    }

    func testComparisonNeverMutatesSnapshotEntries() throws {
        try seedKnownPair()
        let entriesBefore = try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: leftSnapshot)
        let snapshotBefore = try EntrySnapshotProbe.snapshotFingerprint(database: database, snapshotID: leftSnapshot)

        _ = try compare()

        XCTAssertEqual(try EntrySnapshotProbe.contentFingerprint(database: database, snapshotID: leftSnapshot), entriesBefore)
        XCTAssertEqual(try EntrySnapshotProbe.snapshotFingerprint(database: database, snapshotID: leftSnapshot), snapshotBefore)
    }
}
