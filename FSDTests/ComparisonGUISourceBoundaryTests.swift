import XCTest

/// Deterministic source-boundary checks for the Milestone 4 comparison GUI
/// correction: no raw SQL, no schema/table-name knowledge, and no
/// `ComparisonMetadataDataSource` in the comparison UI sources; the shared
/// empty-state component is project-referenced and the app shell no longer
/// declares a private duplicate; and the UI models consume only the approved
/// repository APIs.
final class ComparisonGUISourceBoundaryTests: XCTestCase {
    /// The repository root, derived from this file's own path
    /// (`FSDTests/ComparisonGUISourceBoundaryTests.swift` → repo root), the
    /// same derivation `CatalogSchemaFixture` uses for `schema.sql`.
    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private var uiDirectory: URL { repoRoot.appendingPathComponent("FSD/UI") }

    private func sourceText(fileName: String) throws -> String {
        try String(contentsOf: uiDirectory.appendingPathComponent(fileName), encoding: .utf8)
    }

    private func uiSourceFileNames() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: uiDirectory.path)
            .filter { $0.hasPrefix("Comparison") && $0.hasSuffix(".swift") }
            .sorted()
    }

    // MARK: - Raw SQL prohibition

    func testNoRawSQLOrSchemaKnowledgeInComparisonUISources() throws {
        let files = try uiSourceFileNames()
        XCTAssertFalse(files.isEmpty, "comparison UI sources must exist to be checked")
        let forbiddenTokens = [
            ".query(", ".execute(", ".scalar(", "executeWithRowCount",
            "PRAGMA", "ComparisonMetadataDataSource",
            "FROM entries", "FROM comparison_results", "FROM snapshots", "FROM comparisons",
            "SELECT ", "INSERT INTO", "UPDATE ", "DELETE FROM", "CREATE "
        ]
        for fileName in files {
            let text = try sourceText(fileName: fileName)
            for token in forbiddenTokens {
                XCTAssertFalse(
                    text.contains(token),
                    "\(fileName) must not contain '\(token)': the UI layer cannot issue SQL or know schema names"
                )
            }
        }
    }

    func testBrowserModelReadsMetadataOnlyThroughRepositoryAPIs() throws {
        let text = try sourceText(fileName: "ComparisonBrowserModel.swift")
        XCTAssertTrue(text.contains("entryMetadata("), "browser model must use the repository metadata API")
        XCTAssertTrue(text.contains("fieldDifferences(for:"), "browser model must use the repository field-difference API")
        XCTAssertTrue(text.contains("position(of:"), "browser model uses the navigation offset adapter")
        XCTAssertFalse(text.contains("ComparisonMetadataDataSource"), "GUI-owned SQL data source must be gone")
    }

    func testWorkspaceModelRoutesDisposalThroughApprovedAPIs() throws {
        let text = try sourceText(fileName: "ComparisonWorkspaceModel.swift")
        XCTAssertTrue(text.contains("resultRepository.deleteComparison("), "explicit disposal API (ADR-027/028)")
        XCTAssertTrue(text.contains("cleanupUnreferencedTransients()"), "lifecycle transient release (ADR-012)")
        XCTAssertTrue(text.contains("closeWorkspace()"), "canonical workspace close path")
        XCTAssertFalse(text.contains("DELETE FROM"), "no raw SQL disposal")
    }

    // MARK: - Shared empty-state component

    func testSharedEmptyStateComponentIsProjectReferencedAndNotDuplicated() throws {
        // The app shell no longer declares a private duplicate.
        let appText = try String(contentsOf: repoRoot.appendingPathComponent("FSD/App/FSDApp.swift"), encoding: .utf8)
        XCTAssertFalse(appText.contains("private struct EmptyStateView"), "app shell must not hide the shared component")

        // The shared file declares the component once.
        let sharedText = try sourceText(fileName: "ComparisonSharedViews.swift")
        XCTAssertTrue(sharedText.contains("struct EmptyStateView: View"), "shared component file must exist")

        // The project references the shared file in both build phases.
        let projectText = try String(contentsOf: repoRoot.appendingPathComponent("FSD.xcodeproj/project.pbxproj"), encoding: .utf8)
        XCTAssertTrue(projectText.contains("A10000000000000000000506 /* ComparisonSharedViews.swift in Sources */"), "app target must compile the shared component")
        XCTAssertTrue(projectText.contains("A20000000000000000000506 /* ComparisonSharedViews.swift */"), "project must reference the shared component file")
    }

    // MARK: - Backend boundary

    func testBackendResultAPIStillExposesTheApprovedContract() throws {
        // The repository is the approved read API the GUI consumes. Its
        // public contract must remain intact (backend semantics unchanged by
        // this GUI task; the only additive member is the navigation offset).
        let repositoryText = try String(contentsOf: repoRoot.appendingPathComponent("FSD/Diff/ComparisonResultRepository.swift"), encoding: .utf8)
        XCTAssertTrue(repositoryText.contains("public func entryMetadata"))
        XCTAssertTrue(repositoryText.contains("public func fieldDifferences"))
        XCTAssertTrue(repositoryText.contains("public func navigate"))
        XCTAssertTrue(repositoryText.contains("public func position("))
        XCTAssertTrue(repositoryText.contains("public static let maximumPageSize = 5000"), "bounded paging ceiling unchanged")
    }

    func testSchemaAndMigrationsAreUntouchedByTheGUITask() throws {
        // The GUI task must not reach into schema, migrations, engine, service
        // or lifecycle files. The UI sources cannot reference them either.
        let uiText = try uiSourceFileNames().map { try sourceText(fileName: $0) }.joined(separator: "\n")
        XCTAssertFalse(uiText.contains("CatalogMigrations"))
        XCTAssertFalse(uiText.contains("schema.sql"))
        XCTAssertFalse(uiText.contains("ExpectedState"))
        XCTAssertFalse(uiText.contains("ComparisonEngine("), "the GUI must not construct the matching engine directly")
    }

    func testSchemaFileRecordsVersionNine() throws {
        let schema = try String(contentsOf: repoRoot.appendingPathComponent("docs/database/schema.sql"), encoding: .utf8)
        XCTAssertTrue(schema.contains("INSERT OR IGNORE INTO schema_migrations(version, applied_at)"), "schema version row seeding must remain")
        XCTAssertTrue(schema.contains("VALUES (9, CURRENT_TIMESTAMP);"), "schema must record current version 9")
    }
}
