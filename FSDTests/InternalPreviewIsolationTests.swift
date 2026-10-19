import XCTest
import SQLite3
@testable import FSD

/// Mandatory Task065 separation checks: the Internal Preview flavor must resolve
/// only its own catalog, the production flavor must keep its existing behavior,
/// and the XCTest host must stay isolated. These use generated temporary
/// catalogs only; they never touch the Owner's production or preview data.
final class InternalPreviewIsolationTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-task065-isolation-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        directory = nil
    }

    private var canonicalSchemaURL: URL { CatalogSchemaFixture.canonicalSchemaURL }

    // MARK: - Flavor selection is compile-time

    func testPreviewFlavorIsSelectedOnlyByTheCompileTimeFlag() {
        // The test host is a normal Debug production-flavor build, so the
        // compiled flavor is production even though preview behavior is
        // explicitly exercised below.
        XCTAssertEqual(CatalogLocationResolver.Flavor.buildTime, .production)
        #if FSD_INTERNAL_PREVIEW
        XCTFail("The FSDTests host must not be built with FSD_INTERNAL_PREVIEW")
        #endif
    }

    // MARK: - Production flavor is unchanged

    func testProductionFlavorResolvesApplicationSupportAndRejectsOverrides() throws {
        let defaultURL = try CatalogLocationResolver.defaultURL()
        let rejected = try CatalogLocationResolver.resolve(
            arguments: ["/path/to/FSD", "-FSDCatalogPath", directory.appendingPathComponent("elsewhere.sqlite3").path],
            environment: [:],
            overrideAllowed: false,
            flavor: .production
        )
        XCTAssertEqual(rejected.origin, .applicationSupport)
        XCTAssertEqual(rejected.url, defaultURL)
        XCTAssertEqual(rejected.rejectedOverridePath, directory.appendingPathComponent("elsewhere.sqlite3").path)
        XCTAssertFalse(rejected.isInternalPreview)

        // The DEBUG development branch still honours an override, but that is
        // the production flavor's existing behavior, not the preview path.
        let honoured = try CatalogLocationResolver.resolve(
            arguments: ["/path/to/FSD", "-FSDCatalogPath", directory.path],
            environment: [:],
            overrideAllowed: true,
            flavor: .production
        )
        XCTAssertEqual(honoured.origin, .launchArgument)
        XCTAssertEqual(honoured.url.lastPathComponent, CatalogDatabase.defaultDatabaseFileName)
        XCTAssertFalse(honoured.isInternalPreview)
    }

    // MARK: - Preview flavor isolation

    func testInternalPreviewWithoutFlagsResolvesOnlyItsDedicatedCatalog() throws {
        let location = try CatalogLocationResolver.resolve(
            arguments: ["/Applications/FSD2InternalPreview.app/Contents/MacOS/FSD2InternalPreview"],
            environment: [:],
            flavor: .internalPreview
        )
        XCTAssertEqual(location.origin, .internalPreview)
        XCTAssertTrue(location.isInternalPreview)
        XCTAssertEqual(location.url.lastPathComponent, CatalogDatabase.defaultDatabaseFileName)
        XCTAssertEqual(location.url.deletingLastPathComponent().lastPathComponent, CatalogLocationResolver.internalPreviewDirectoryName)

        // Never the production directory, and never the production file.
        XCTAssertNotEqual(location.url, try CatalogLocationResolver.defaultURL())
        XCTAssertFalse(location.url.path.contains("/Application Support/FSD/catalog.sqlite3"))
    }

    func testInternalPreviewIgnoresProductionPathOverrideAndReportsIt() throws {
        let productionLooking = directory.appendingPathComponent("FSD/catalog.sqlite3")
        let location = try CatalogLocationResolver.resolve(
            arguments: ["app", "-FSDCatalogPath", productionLooking.path],
            environment: [CatalogLocationResolver.environmentVariableName: productionLooking.path],
            flavor: .internalPreview
        )
        XCTAssertEqual(location.origin, .internalPreview)
        XCTAssertTrue(location.isInternalPreview)
        XCTAssertNotEqual(location.url, productionLooking)
        XCTAssertEqual(location.rejectedOverridePath, productionLooking.path)
        XCTAssertTrue(location.diagnosticLine.contains("Internal Preview"))
        XCTAssertTrue(location.diagnosticLine.contains("dedicated catalog"))
    }

    func testInternalPreviewDoesNotFallBackToProductionWhenApplicationSupportIsUnavailable() throws {
        let defaultURL = try CatalogLocationResolver.defaultURL()
        XCTAssertThrowsError(try CatalogLocationResolver.resolve(
            arguments: [],
            environment: [:],
            fileManager: EmptyApplicationSupportFileManager(),
            flavor: .internalPreview
        )) { error in
            // It must fail loudly with the preview error and must not surface any
            // production path.
            XCTAssertEqual(error as? CatalogLocationError, .internalPreviewUnavailable)
            XCTAssertFalse((error as? CatalogLocationError)?.errorDescription?.contains(defaultURL.path) == true)
        }
    }

    func testInternalPreviewUnavailableThrowsInsteadOfFallingBack() throws {
        XCTAssertThrowsError(try CatalogLocationResolver.internalPreviewURL(fileManager: EmptyApplicationSupportFileManager())) { error in
            XCTAssertEqual(error as? CatalogLocationError, .internalPreviewUnavailable)
        }
    }

    func testTestHostAlwaysUsesItsOwnIsolatedCatalogEvenInPreviewFlavor() throws {
        let location = try CatalogLocationResolver.resolve(
            arguments: [],
            environment: ["XCTestBundlePath": "/tmp/FSDTests.xctest"],
            flavor: .internalPreview
        )
        XCTAssertEqual(location.origin, .testHost)
        XCTAssertEqual(location.url, CatalogLocationResolver.testHostCatalogURL())
        XCTAssertNotEqual(location.url.deletingLastPathComponent().lastPathComponent, CatalogLocationResolver.internalPreviewDirectoryName)
    }

    func testPreviewTestRootSeamStaysInsideTheExplicitRoot() throws {
        let root = directory.appendingPathComponent("isolated-preview-root", isDirectory: true)
        let location = try CatalogLocationResolver.resolve(
            arguments: [],
            environment: [CatalogLocationResolver.internalPreviewTestRootVariableName: root.path],
            flavor: .internalPreview
        )
        XCTAssertEqual(location.origin, .internalPreview)
        XCTAssertEqual(location.url, root.appendingPathComponent(CatalogDatabase.defaultDatabaseFileName))
        XCTAssertTrue(location.url.path.hasPrefix(root.path))
    }

    // MARK: - Independent locks and persistence roots

    func testPreviewAndProductionHaveIndependentProcessLocks() throws {
        let previewURL = directory.appendingPathComponent("FSD-Internal-Preview/catalog.sqlite3")
        let productionURL = directory.appendingPathComponent("FSD/catalog.sqlite3")
        let previewLock = try CatalogProcessLock(catalogURL: previewURL)
        let productionLock = try CatalogProcessLock(catalogURL: productionURL)
        XCTAssertTrue(previewLock.isHeld)
        XCTAssertTrue(productionLock.isHeld)
        XCTAssertNotEqual(previewLock.lockURL, productionLock.lockURL)
        previewLock.unlock()
        productionLock.unlock()
    }

    func testTwoPreviewInstancesShareOneCatalogLock() throws {
        let previewURL = directory.appendingPathComponent("FSD-Internal-Preview/catalog.sqlite3")
        let first = try CatalogProcessLock(catalogURL: previewURL)
        XCTAssertThrowsError(try CatalogProcessLock(catalogURL: previewURL)) { error in
            guard case CatalogProcessLock.LockError.alreadyLocked = error else {
                return XCTFail("Expected alreadyLocked, got \(error)")
            }
        }
        first.unlock()
        let afterRelease = try CatalogProcessLock(catalogURL: previewURL)
        XCTAssertTrue(afterRelease.isHeld)
        afterRelease.unlock()
    }

    func testPreviewRelaunchPreservesItsOwnData() throws {
        let previewURL = directory.appendingPathComponent("FSD-Internal-Preview/catalog.sqlite3")
        do {
            let database = try CatalogDatabase(url: previewURL, schemaURL: canonicalSchemaURL)
            _ = try SnapshotCollectionRepository(database: database).createCollection(name: "Preview only")
            database.close()
        }
        let reopened = try CatalogDatabase(url: previewURL, schemaURL: canonicalSchemaURL)
        let collections = try SnapshotCollectionRepository(database: reopened).listCollections(limit: 50)
        XCTAssertTrue(collections.collections.contains { $0.name == "Preview only" })
        XCTAssertEqual(try reopened.schemaVersion, CatalogDatabase.currentSchemaVersion)
        reopened.close()
    }

    func testPreviewCatalogPathIsNeverTheProductionCatalog() throws {
        XCTAssertNotEqual(
            try CatalogLocationResolver.internalPreviewURL(),
            try CatalogLocationResolver.defaultURL()
        )
    }

    // MARK: - Migration through v13 with rollback safety

    func testGeneratedLegacyCatalogMigratesThroughV13() throws {
        let legacyURL = directory.appendingPathComponent("legacy-v12-catalog.sqlite3")
        try CatalogSchemaFixture.createDatabase(at: legacyURL, sql: CatalogSchemaFixture.version12SQL())
        XCTAssertEqual(try rawVersion(at: legacyURL), 12)

        let migrated = try CatalogDatabase(url: legacyURL)
        XCTAssertEqual(try migrated.schemaVersion, CatalogDatabase.currentSchemaVersion)
        XCTAssertEqual(try migrated.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try migrated.query("PRAGMA foreign_key_check").isEmpty)
        let versions = try migrated.query("SELECT version FROM schema_migrations ORDER BY version").compactMap { $0["version"]?.int64Value }
        XCTAssertEqual(versions.last, CatalogDatabase.currentSchemaVersion)
        migrated.close()
    }

    func testFailedPreviewMigrationRollsBackWithoutDamagingItsInput() throws {
        let legacyURL = directory.appendingPathComponent("legacy-v12-rollback.sqlite3")
        try CatalogSchemaFixture.createDatabase(at: legacyURL, sql: CatalogSchemaFixture.version12SQL())
        // Capture the v12 version row before the failed migration.
        XCTAssertEqual(try rawVersion(at: legacyURL), 12)

        let failing = [SchemaMigration(version: 13, statements: ["INSERT INTO table_that_does_not_exist VALUES (1)"])]
        XCTAssertThrowsError(try CatalogDatabase(url: legacyURL, migrations: failing)) { error in
            guard case CatalogDatabaseError.migrationFailed = error else {
                return XCTFail("Expected migrationFailed, got \(error)")
            }
        }
        // The input is unchanged: still v12, still readable, no partial v13 row.
        XCTAssertEqual(try rawVersion(at: legacyURL), 12)
        let recovered = try CatalogDatabase(url: legacyURL)
        XCTAssertEqual(try recovered.schemaVersion, CatalogDatabase.currentSchemaVersion)
        recovered.close()
    }

    // MARK: - Helpers

    private func rawVersion(at url: URL) throws -> Int64 {
        var handle: OpaquePointer?
        guard url.path.withCString({ sqlite3_open_v2($0, &handle, SQLITE_OPEN_READONLY, nil) }) == SQLITE_OK, let handle else {
            throw NSError(domain: "InternalPreviewIsolationTests", code: 1)
        }
        defer { sqlite3_close(handle) }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, "SELECT MAX(version) FROM schema_migrations", -1, &statement, nil) == SQLITE_OK,
              let statement else { throw NSError(domain: "InternalPreviewIsolationTests", code: 2) }
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW else { throw NSError(domain: "InternalPreviewIsolationTests", code: 3) }
        return sqlite3_column_int64(statement, 0)
    }
}

/// A FileManager whose Application Support lookup fails, so the "no fallback"
/// behavior can be exercised without disturbing the real filesystem.
private final class EmptyApplicationSupportFileManager: FileManager {
    override func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        []
    }
}
