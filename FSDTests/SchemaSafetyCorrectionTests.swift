import XCTest
@testable import FSD

/// Milestone 4 schema-safety correction (ADR-028) regression tests.
///
/// `TerminalCollisionEvidenceTests` proves at the SQLite boundary that a
/// terminal comparison's collision groups and members are immutable across
/// INSERT/UPDATE/DELETE while writes stay legal during `running`, that
/// ordinary result-row deletion is rejected after the terminal state, and
/// that whole-comparison disposal (the explicit API) still cascades without
/// residue.
///
/// `ExpectedStateInventoryTests` keeps `CatalogMigrations.ExpectedState` in
/// lockstep with `docs/database/schema.sql` and proves that a catalog
/// reporting version 8 is rejected when any required object is missing or
/// when a safety-critical trigger keeps its name but loses its definition.
final class TerminalCollisionEvidenceTests: XCTestCase {
    private var directory: URL!
    private var database: CatalogDatabase!
    private var results: ComparisonResultRepository!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-Safety-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        database = try CatalogDatabase(
            url: directory.appendingPathComponent("catalog.sqlite3"),
            schemaURL: CatalogSchemaFixture.canonicalSchemaURL
        )
        results = ComparisonResultRepository(database: database)
    }

    override func tearDownWithError() throws {
        results = nil
        database?.close()
        database = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
    }

    /// A `running` comparison with one collision group holding two members.
    /// `seed` shifts every id so a test that seeds repeatedly (one per
    /// terminal state) never collides.
    private func seedRunningComparisonWithCollision(
        seed: Int64 = 0
    ) throws -> (comparisonID: Int64, groupID: Int64, leftRootID: Int64, rightRootID: Int64) {
        let volumeID = 900 + seed
        let leftRootID = 901 + seed * 2
        let rightRootID = 902 + seed * 2
        let leftID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: volumeID, session: 1, sensitivity: .sensitive)
        let rightID = try SyntheticSnapshot.createSnapshot(database: database, volumeID: volumeID, session: 2, sensitivity: .sensitive)
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: leftID, entries: [
            SyntheticSnapshot.root(id: leftRootID, name: "Root")
        ])
        try SyntheticSnapshot.insertEntries(database: database, snapshotID: rightID, entries: [
            SyntheticSnapshot.root(id: rightRootID, name: "Root")
        ])
        try SyntheticSnapshot.complete(database: database, snapshotID: leftID)
        try SyntheticSnapshot.complete(database: database, snapshotID: rightID)

        let comparisonID = 7000 + seed
        let groupID = 7100 + seed
        try database.execute(
            """
            INSERT INTO comparisons (id, left_snapshot_id, right_snapshot_id, profile_id, status, started_at, created_at)
            VALUES (?, ?, ?, 1, 'running', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """,
            bindings: [.integer(comparisonID), .integer(leftID.rawValue), .integer(rightID.rawValue)]
        )
        try database.execute(
            "INSERT INTO comparison_collision_groups (id, comparison_id, result_path, created_at) VALUES (?, ?, '/collide', CURRENT_TIMESTAMP)",
            bindings: [.integer(groupID), .integer(comparisonID)]
        )
        try database.execute(
            "INSERT INTO comparison_collision_members (id, group_id, side, entry_id, created_at) VALUES (?, ?, 'left', ?, CURRENT_TIMESTAMP)",
            bindings: [.integer(groupID * 10 + 1), .integer(groupID), .integer(leftRootID)]
        )
        try database.execute(
            "INSERT INTO comparison_collision_members (id, group_id, side, entry_id, created_at) VALUES (?, ?, 'right', ?, CURRENT_TIMESTAMP)",
            bindings: [.integer(groupID * 10 + 2), .integer(groupID), .integer(rightRootID)]
        )
        return (comparisonID, groupID, leftRootID, rightRootID)
    }

    private func terminalize(_ comparisonID: Int64, status: String) throws {
        try database.execute(
            "UPDATE comparisons SET status = ? WHERE id = ?",
            bindings: [.text(status), .integer(comparisonID)]
        )
    }

    // MARK: - Writes stay allowed while running

    func testCollisionGroupAndMemberInsertAreAllowedWhileRunning() throws {
        let (comparisonID, groupID, _, _) = try seedRunningComparisonWithCollision()
        XCTAssertEqual(
            try database.scalar("SELECT COUNT(*) FROM comparison_collision_groups WHERE comparison_id = ?", bindings: [.integer(comparisonID)])?.int64Value,
            1
        )
        XCTAssertEqual(
            try database.scalar("SELECT COUNT(*) FROM comparison_collision_members WHERE group_id = ?", bindings: [.integer(groupID)])?.int64Value,
            2
        )
    }

    func testCollisionEvidenceMutationIsAllowedWhileRunning() throws {
        let (comparisonID, groupID, _, _) = try seedRunningComparisonWithCollision()
        // UPDATE and DELETE on group and member rows are legal while running.
        try database.execute(
            "UPDATE comparison_collision_groups SET result_path = '/renamed' WHERE id = ?",
            bindings: [.integer(groupID)]
        )
        try database.execute(
            "UPDATE comparison_collision_members SET created_at = CURRENT_TIMESTAMP WHERE group_id = ?",
            bindings: [.integer(groupID)]
        )
        try database.execute(
            "DELETE FROM comparison_collision_members WHERE group_id = ? AND side = 'right'",
            bindings: [.integer(groupID)]
        )
        try database.execute(
            "DELETE FROM comparison_collision_groups WHERE id = ?",
            bindings: [.integer(groupID)]
        )
        XCTAssertEqual(
            try database.scalar("SELECT COUNT(*) FROM comparison_collision_groups WHERE comparison_id = ?", bindings: [.integer(comparisonID)])?.int64Value,
            0
        )
    }

    func testResultRowDeleteIsAllowedWhileRunning() throws {
        let (comparisonID, _, _, _) = try seedRunningComparisonWithCollision()
        try database.execute(
            """
            INSERT INTO comparison_results (comparison_id, result_path, display_name, result_type, created_at)
            VALUES (?, '', 'Root', 'matched', CURRENT_TIMESTAMP)
            """,
            bindings: [.integer(comparisonID)]
        )
        try database.execute(
            "DELETE FROM comparison_results WHERE comparison_id = ?",
            bindings: [.integer(comparisonID)]
        )
        XCTAssertEqual(
            try database.scalar("SELECT COUNT(*) FROM comparison_results WHERE comparison_id = ?", bindings: [.integer(comparisonID)])?.int64Value,
            0
        )
    }

    // MARK: - Terminal states reject direct mutation

    func testCollisionGroupAndMemberMutationIsRejectedAfterEveryTerminalState() throws {
        for (index, status) in ["complete", "cancelled", "failed"].enumerated() {
            let (comparisonID, groupID, leftRootID, _) = try seedRunningComparisonWithCollision(seed: Int64(index))
            try terminalize(comparisonID, status: status)

            XCTAssertThrowsError(try database.execute(
                "INSERT INTO comparison_collision_groups (comparison_id, result_path, created_at) VALUES (?, '/late', CURRENT_TIMESTAMP)",
                bindings: [.integer(comparisonID)]
            ), "group INSERT after \(status)")
            XCTAssertThrowsError(try database.execute(
                "UPDATE comparison_collision_groups SET result_path = '/renamed' WHERE id = ?",
                bindings: [.integer(groupID)]
            ), "group UPDATE after \(status)")
            XCTAssertThrowsError(try database.execute(
                "DELETE FROM comparison_collision_groups WHERE id = ?",
                bindings: [.integer(groupID)]
            ), "group DELETE after \(status)")
            XCTAssertThrowsError(try database.execute(
                "INSERT INTO comparison_collision_members (group_id, side, entry_id, created_at) VALUES (?, 'left', ?, CURRENT_TIMESTAMP)",
                bindings: [.integer(groupID), .integer(leftRootID)]
            ), "member INSERT after \(status)")
            XCTAssertThrowsError(try database.execute(
                "UPDATE comparison_collision_members SET side = 'right' WHERE group_id = ?",
                bindings: [.integer(groupID)]
            ), "member UPDATE after \(status)")
            XCTAssertThrowsError(try database.execute(
                "DELETE FROM comparison_collision_members WHERE group_id = ?",
                bindings: [.integer(groupID)]
            ), "member DELETE after \(status)")

            // The retained evidence is untouched.
            XCTAssertEqual(
                try database.scalar("SELECT COUNT(*) FROM comparison_collision_groups WHERE comparison_id = ?", bindings: [.integer(comparisonID)])?.int64Value,
                1
            )
            XCTAssertEqual(
                try database.scalar("SELECT COUNT(*) FROM comparison_collision_members WHERE group_id = ?", bindings: [.integer(groupID)])?.int64Value,
                2
            )
        }
    }

    func testResultRowDeleteIsRejectedAfterTerminalState() throws {
        for (index, status) in ["complete", "cancelled", "failed"].enumerated() {
            let (comparisonID, _, _, _) = try seedRunningComparisonWithCollision(seed: Int64(index))
            try database.execute(
                """
                INSERT INTO comparison_results (comparison_id, result_path, display_name, result_type, created_at)
                VALUES (?, '/uncertain', 'uncertain', 'uncertain', CURRENT_TIMESTAMP)
                """,
                bindings: [.integer(comparisonID)]
            )
            try terminalize(comparisonID, status: status)

            XCTAssertThrowsError(try database.execute(
                "DELETE FROM comparison_results WHERE comparison_id = ?",
                bindings: [.integer(comparisonID)]
            ), "result DELETE after \(status)")
            XCTAssertEqual(
                try database.scalar("SELECT COUNT(*) FROM comparison_results WHERE comparison_id = ?", bindings: [.integer(comparisonID)])?.int64Value,
                1,
                "the retained conclusion row survives after \(status)"
            )
        }
    }

    // MARK: - Whole-comparison disposal still cascades

    func testWholeComparisonDisposalCascadesWithoutResidue() throws {
        let (comparisonID, _, _, _) = try seedRunningComparisonWithCollision()
        let comparison = ComparisonID(rawValue: comparisonID)

        try results.deleteComparison(comparison)

        XCTAssertEqual(try results.count(), 0)
        XCTAssertNil(try results.record(id: comparison))
        XCTAssertEqual(
            try database.scalar("SELECT COUNT(*) FROM comparison_collision_groups WHERE comparison_id = ?", bindings: [.integer(comparisonID)])?.int64Value,
            0,
            "collision groups cascade with the comparison"
        )
        XCTAssertEqual(
            try database.scalar(
                "SELECT COUNT(*) FROM comparison_collision_members m JOIN comparison_collision_groups g ON m.group_id = g.id WHERE g.comparison_id = ?",
                bindings: [.integer(comparisonID)]
            )?.int64Value, 0,
            "collision members cascade with the comparison"
        )
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
    }

    func testTerminalComparisonDisposalStillCascades() throws {
        let (comparisonID, groupID, _, _) = try seedRunningComparisonWithCollision()
        try terminalize(comparisonID, status: "complete")
        let comparison = ComparisonID(rawValue: comparisonID)

        try results.deleteComparison(comparison)

        XCTAssertEqual(
            try database.scalar("SELECT COUNT(*) FROM comparison_collision_groups WHERE comparison_id = ?", bindings: [.integer(comparisonID)])?.int64Value,
            0
        )
        XCTAssertEqual(
            try database.scalar("SELECT COUNT(*) FROM comparison_collision_members WHERE group_id = ?", bindings: [.integer(groupID)])?.int64Value,
            0
        )
        XCTAssertEqual(try results.count(), 0)
        XCTAssertEqual(try database.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try database.query("PRAGMA foreign_key_check").isEmpty)
    }

    func testGuardsLeaveSnapshotsAndEntriesUntouched() throws {
        let (comparisonID, groupID, leftRootID, _) = try seedRunningComparisonWithCollision()
        let snapshotsBefore = try database.scalar("SELECT COUNT(*) FROM snapshots WHERE id IN (SELECT snapshot_id FROM entries WHERE id = ?)", bindings: [.integer(leftRootID)])?.int64Value ?? 0
        XCTAssertEqual(snapshotsBefore, 1)

        try terminalize(comparisonID, status: "complete")
        // Attempt every terminal mutation; snapshots and entries must survive.
        _ = try? database.execute(
            "INSERT INTO comparison_collision_groups (comparison_id, result_path, created_at) VALUES (?, '/x', CURRENT_TIMESTAMP)",
            bindings: [.integer(comparisonID)]
        )
        _ = try? database.execute(
            "DELETE FROM comparison_collision_members WHERE group_id = ?",
            bindings: [.integer(groupID)]
        )
        XCTAssertEqual(
            try database.scalar("SELECT COUNT(*) FROM entries WHERE id IN (901, 902)")?.int64Value,
            2,
            "the entry rows behind the collision evidence are untouched"
        )
        XCTAssertEqual(
            try database.scalar("SELECT COUNT(*) FROM snapshots")?.int64Value,
            2,
            "both snapshots survive the terminal guards"
        )
    }
}

final class ExpectedStateInventoryTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-ExpectedState-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        directory = nil
    }

    // MARK: - Canonical inventory parsing (mirror of the schema file's DDL)

    /// Parses every `CREATE <keyword>` statement in a schema script and
    /// returns (name, statement text) pairs in file order.
    private func parseStatements(from text: String, keyword: String) -> [(String, String)] {
        var results: [(String, String)] = []
        var searchStart = text.startIndex
        let pattern = "CREATE\\s+\(keyword)\\b"
        while let match = text.range(of: pattern, options: [.regularExpression, .caseInsensitive], range: searchStart..<text.endIndex) {
            let statementStart = match.lowerBound
            let statementEnd: String.Index
            if keyword == "TRIGGER" {
                guard let terminator = text.range(of: "\nEND;", options: [], range: statementStart..<text.endIndex) else { break }
                statementEnd = terminator.upperBound
            } else {
                var depth = 0
                var cursor = statementStart
                var found = false
                while cursor < text.endIndex {
                    let character = text[cursor]
                    if character == "(" {
                        depth += 1
                    } else if character == ")" {
                        depth -= 1
                    } else if character == ";" && depth == 0 {
                        found = true
                        break
                    }
                    cursor = text.index(after: cursor)
                }
                guard found else { break }
                statementEnd = text.index(after: cursor)
            }
            let statement = String(text[statementStart..<statementEnd])
            let namePattern = "CREATE\\s+\(keyword)\\s+(?:IF\\s+NOT\\s+EXISTS\\s+)?([A-Za-z_][A-Za-z0-9_]*)"
            guard let nameMatch = statement.range(of: namePattern, options: [.regularExpression, .caseInsensitive]) else { break }
            let name = statement[nameMatch]
                .split(whereSeparator: { $0.isWhitespace })
                .last
                .map(String.init) ?? ""
            results.append((name, statement))
            searchStart = statementEnd
        }
        return results
    }

    // MARK: - Inventory parity with schema.sql

    func testExpectedStateCoversTheCompleteCanonicalObjectInventory() throws {
        let schema = try String(contentsOf: CatalogSchemaFixture.canonicalSchemaURL, encoding: .utf8)

        let schemaTriggers = Set(parseStatements(from: schema, keyword: "TRIGGER").map(\.0))
        let schemaIndexes = Set(parseStatements(from: schema, keyword: "INDEX").map(\.0))
        let schemaTables = Set(parseStatements(from: schema, keyword: "TABLE").map(\.0))

        let expectedTriggers = Set(CatalogMigrations.ExpectedState.triggerDefinitions.map(\.name))
        let expectedIndexes = Set(CatalogMigrations.ExpectedState.indexDefinitions.map(\.name))
        let expectedTables = Set(CatalogMigrations.ExpectedState.tables)

        XCTAssertEqual(schemaTriggers, expectedTriggers,
                       "a trigger exists in schema.sql but is absent from ExpectedState, or vice versa")
        XCTAssertEqual(schemaIndexes, expectedIndexes,
                       "an index exists in schema.sql but is absent from ExpectedState, or vice versa")
        XCTAssertEqual(schemaTables, expectedTables,
                       "a table exists in schema.sql but is absent from ExpectedState, or vice versa")
    }

    func testExpectedStateDefinitionsMatchTheCanonicalSchemaText() throws {
        let schema = try String(contentsOf: CatalogSchemaFixture.canonicalSchemaURL, encoding: .utf8)
        let normalize = CatalogMigrations.ExpectedState.normalizedObjectSQL

        for (name, statement) in parseStatements(from: schema, keyword: "TRIGGER") {
            guard let canonical = CatalogMigrations.ExpectedState.triggerDefinitions.first(where: { $0.name == name }) else {
                return XCTFail("ExpectedState is missing trigger \(name)")
            }
            XCTAssertEqual(normalize(statement), normalize(canonical.sql),
                           "canonical ExpectedState definition drifted from schema.sql for trigger \(name)")
        }
        for (name, statement) in parseStatements(from: schema, keyword: "INDEX") {
            guard let canonical = CatalogMigrations.ExpectedState.indexDefinitions.first(where: { $0.name == name }) else {
                return XCTFail("ExpectedState is missing index \(name)")
            }
            XCTAssertEqual(normalize(statement), normalize(canonical.sql),
                           "canonical ExpectedState definition drifted from schema.sql for index \(name)")
        }
    }

    // MARK: - Damaged v8 catalogs are rejected

    private func makeFreshV8Catalog(named name: String) throws -> URL {
        let url = directory.appendingPathComponent("\(name).sqlite3")
        let database = try CatalogDatabase(url: url, schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        database.close()
        return url
    }

    private func assertReopenFails(at url: URL, mentioning expected: String, file: StaticString = #filePath, line: UInt = #line) throws {
        XCTAssertThrowsError(try CatalogDatabase(url: url), file: file, line: line) { error in
            guard case let CatalogDatabaseError.schemaStateInvalid(detail) = error else {
                return XCTFail("Unexpected error: \(error)", file: file, line: line)
            }
            XCTAssertTrue(detail.contains(expected), "expected \(expected) in \(detail)", file: file, line: line)
        }
    }

    func testDamagedV8CatalogRejectsMissingBaselineIndex() throws {
        let url = try makeFreshV8Catalog(named: "drift-missing-index")
        try CatalogSchemaFixture.createDatabase(at: url, sql: "DROP INDEX idx_entries_snapshot_parent_sort;")
        try assertReopenFails(at: url, mentioning: "idx_entries_snapshot_parent_sort")
    }

    func testDamagedV8CatalogRejectsMissingBaselineTrigger() throws {
        let url = try makeFreshV8Catalog(named: "drift-missing-trigger")
        try CatalogSchemaFixture.createDatabase(at: url, sql: "DROP TRIGGER trg_snapshots_terminal_status_check;")
        try assertReopenFails(at: url, mentioning: "trg_snapshots_terminal_status_check")
    }

    func testDamagedV8CatalogRejectsMissingV7CollisionGuard() throws {
        let url = try makeFreshV8Catalog(named: "drift-missing-v7-guard")
        try CatalogSchemaFixture.createDatabase(at: url, sql: "DROP TRIGGER trg_comparison_collision_groups_insert_guard;")
        try assertReopenFails(at: url, mentioning: "trg_comparison_collision_groups_insert_guard")
    }

    func testDamagedV8CatalogRejectsSameNameSubstitutedSafetyTrigger() throws {
        let url = try makeFreshV8Catalog(named: "drift-substituted-trigger")
        try CatalogSchemaFixture.createDatabase(at: url, sql: """
        DROP TRIGGER trg_comparisons_terminal_immutable;
        CREATE TRIGGER trg_comparisons_terminal_immutable
        BEFORE UPDATE ON comparisons
        BEGIN
            SELECT RAISE(ABORT, 'substituted guard');
        END;
        """)
        try assertReopenFails(at: url, mentioning: "trg_comparisons_terminal_immutable")
    }

    func testDamagedV8CatalogRejectsSameNameSubstitutedV7Guard() throws {
        let url = try makeFreshV8Catalog(named: "drift-substituted-v7-guard")
        try CatalogSchemaFixture.createDatabase(at: url, sql: """
        DROP TRIGGER trg_comparison_collision_groups_delete_guard;
        CREATE TRIGGER trg_comparison_collision_groups_delete_guard
        BEFORE DELETE ON comparison_collision_groups
        BEGIN
            SELECT RAISE(ABORT, 'substituted');
        END;
        """)
        try assertReopenFails(at: url, mentioning: "trg_comparison_collision_groups_delete_guard")
    }

    func testDamagedV8CatalogRejectsMissingParentResultCascadeIndex() throws {
        let url = try makeFreshV8Catalog(named: "drift-missing-parent-result-index")
        try CatalogSchemaFixture.createDatabase(at: url, sql: "DROP INDEX idx_comparison_results_parent_result_id;")
        try assertReopenFails(at: url, mentioning: "idx_comparison_results_parent_result_id")
    }

    func testDamagedV8CatalogRejectsSameNameParentResultIndexWithWrongColumns() throws {
        let url = try makeFreshV8Catalog(named: "drift-wrong-parent-result-columns")
        try CatalogSchemaFixture.createDatabase(at: url, sql: """
        DROP INDEX idx_comparison_results_parent_result_id;
        CREATE INDEX idx_comparison_results_parent_result_id ON comparison_results(comparison_id);
        """)
        try assertReopenFails(at: url, mentioning: "idx_comparison_results_parent_result_id")
    }

    func testDamagedV8CatalogRejectsSameNameParentResultIndexWithWrongOrdering() throws {
        let url = try makeFreshV8Catalog(named: "drift-wrong-parent-result-order")
        try CatalogSchemaFixture.createDatabase(at: url, sql: """
        DROP INDEX idx_comparison_results_parent_result_id;
        CREATE INDEX idx_comparison_results_parent_result_id ON comparison_results(parent_result_id DESC);
        """)
        try assertReopenFails(at: url, mentioning: "idx_comparison_results_parent_result_id")
    }
}
