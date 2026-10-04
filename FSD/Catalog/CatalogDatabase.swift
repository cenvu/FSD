import Foundation
import SQLite3

public enum CatalogDatabaseError: Error, LocalizedError, Equatable {
    case cannotOpen(URL, Int32, String)
    case sqlite(Int32, String)
    case missingSchemaResource
    case unsupportedSchemaVersion(Int64?)
    case foreignKeysNotEnabled
    case invalidSchemaVersion(Int64?)
    case migrationFailed(Int64, String)
    case schemaStateInvalid(String)

    public var errorDescription: String? {
        switch self {
        case let .cannotOpen(url, code, message):
            return "Cannot open catalog at \(url.path) (SQLite \(code)): \(message)"
        case let .sqlite(code, message):
            return "SQLite error \(code): \(message)"
        case .missingSchemaResource:
            return "The bundled catalog schema resource is missing."
        case let .unsupportedSchemaVersion(version):
            if let version { return "Unsupported catalog schema version \(version); no implicit migration is available." }
            return "The catalog schema version is missing or incomplete; no implicit migration is available."
        case .foreignKeysNotEnabled:
            return "SQLite foreign-key enforcement could not be enabled."
        case let .invalidSchemaVersion(version):
            return "Schema bootstrap completed with unexpected version \(version.map(String.init) ?? "NULL")."
        case let .migrationFailed(version, message):
            return "Catalog migration to schema version \(version) failed and was rolled back: \(message)"
        case let .schemaStateInvalid(detail):
            return "The catalog schema does not match schema version \(CatalogMigrations.currentVersion): \(detail)"
        }
    }
}

public enum DatabaseValue: Equatable {
    case null
    case integer(Int64)
    case real(Double)
    case text(String)
    case blob(Data)

    public var int64Value: Int64? {
        if case let .integer(value) = self { return value }
        return nil
    }

    public var realValue: Double? {
        if case let .real(value) = self { return value }
        if case let .integer(value) = self { return Double(value) }
        return nil
    }

    public var stringValue: String? {
        if case let .text(value) = self { return value }
        return nil
    }
}

public typealias DatabaseRow = [String: DatabaseValue]

/// SQLite access is serialized by `lock`; callers may safely move this
/// reference across the scanner/search worker boundary. Statements are
/// finalized before the lock is released, and `close()` uses the same lock so
/// teardown cannot race an in-flight catalog operation.
public final class CatalogDatabase: @unchecked Sendable {
    public static let currentSchemaVersion: Int64 = CatalogMigrations.currentVersion
    public static let defaultDatabaseFileName = "catalog.sqlite3"

    public let url: URL

    private var handle: OpaquePointer?
    private let lock = NSRecursiveLock()
    private let migrations: [SchemaMigration]

    /// - Parameters:
    ///   - schemaURL: the canonical `schema.sql` used only when creating a new
    ///     catalog. It is never replayed against an existing database.
    ///   - migrations: the explicit forward migrations. Injectable so a test can
    ///     prove that a failing migration rolls back and leaves the recorded
    ///     version untouched.
    public init(url: URL, schemaURL: URL? = nil, migrations: [SchemaMigration] = CatalogMigrations.all) throws {
        self.url = url
        self.migrations = migrations

        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            throw CatalogDatabaseError.sqlite(SQLITE_CANTOPEN, error.localizedDescription)
        }

        var openedHandle: OpaquePointer?
        let result = url.path.withCString { path in
            sqlite3_open_v2(
                path,
                &openedHandle,
                SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX,
                nil
            )
        }
        guard result == SQLITE_OK, let openedHandle else {
            let message = openedHandle.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown SQLite error"
            if let openedHandle { sqlite3_close(openedHandle) }
            throw CatalogDatabaseError.cannotOpen(url, result, message)
        }
        handle = openedHandle

        do {
            try configureConnection()
            try bootstrapIfNeeded(schemaURL: schemaURL ?? Self.bundledSchemaURL())
        } catch {
            sqlite3_close(openedHandle)
            handle = nil
            throw error
        }
    }

    /// Closes the catalog before its containing temporary directory is
    /// removed. This is idempotent and intentionally lock-protected so tests
    /// and application shutdown can establish the SQLite lifetime explicitly.
    public func close() {
        withLock {
            guard let handle else { return }
            sqlite3_close_v2(handle)
            self.handle = nil
        }
    }

    deinit {
        close()
    }

    public func execute(_ sql: String, bindings: [DatabaseValue] = []) throws {
        try withLock {
            try executeUnlocked(sql, bindings: bindings)
        }
    }

    public func query(_ sql: String, bindings: [DatabaseValue] = []) throws -> [DatabaseRow] {
        try withLock {
            guard let handle else { throw CatalogDatabaseError.sqlite(SQLITE_MISUSE, "Database is closed") }
            let statement = try prepare(sql, handle: handle)
            defer { sqlite3_finalize(statement) }
            try bind(bindings, to: statement)

            var rows: [DatabaseRow] = []
            while true {
                let stepResult = sqlite3_step(statement)
                if stepResult == SQLITE_ROW {
                    var row: DatabaseRow = [:]
                    for index in 0..<sqlite3_column_count(statement) {
                        let name = String(cString: sqlite3_column_name(statement, index))
                        row[name] = value(from: statement, column: index)
                    }
                    rows.append(row)
                } else if stepResult == SQLITE_DONE {
                    return rows
                } else {
                    throw sqliteError(code: stepResult, handle: handle)
                }
            }
        }
    }

    /// Executes a write statement and returns the number of rows it changed
    /// (`sqlite3_changes` on this connection).
    @discardableResult
    public func executeWithRowCount(_ sql: String, bindings: [DatabaseValue] = []) throws -> Int {
        try withLock {
            guard let handle else { throw CatalogDatabaseError.sqlite(SQLITE_MISUSE, "Database is closed") }
            let statement = try prepare(sql, handle: handle)
            defer { sqlite3_finalize(statement) }
            try bind(bindings, to: statement)
            while true {
                let stepResult = sqlite3_step(statement)
                if stepResult == SQLITE_DONE { return Int(sqlite3_changes(handle)) }
                if stepResult != SQLITE_ROW { throw sqliteError(code: stepResult, handle: handle) }
            }
        }
    }

    public func scalar(_ sql: String, bindings: [DatabaseValue] = []) throws -> DatabaseValue? {
        try withLock {
            guard let handle else { throw CatalogDatabaseError.sqlite(SQLITE_MISUSE, "Database is closed") }
            let statement = try prepare(sql, handle: handle)
            defer { sqlite3_finalize(statement) }
            try bind(bindings, to: statement)
            let stepResult = sqlite3_step(statement)
            if stepResult == SQLITE_ROW {
                return value(from: statement, column: 0)
            }
            if stepResult == SQLITE_DONE {
                return nil
            }
            throw sqliteError(code: stepResult, handle: handle)
        }
    }

    public func lastInsertRowID() throws -> Int64 {
        try withLock {
            guard let handle else { throw CatalogDatabaseError.sqlite(SQLITE_MISUSE, "Database is closed") }
            return sqlite3_last_insert_rowid(handle)
        }
    }

    @discardableResult
    public func transaction<T>(_ body: () throws -> T) throws -> T {
        try withLock {
            try executeUnlocked("BEGIN IMMEDIATE")
            do {
                let result = try body()
                try executeUnlocked("COMMIT")
                return result
            } catch {
                _ = try? executeUnlocked("ROLLBACK")
                throw error
            }
        }
    }

    public var schemaVersion: Int64 {
        get throws {
            guard let value = try scalar("SELECT MAX(version) FROM schema_migrations") else {
                throw CatalogDatabaseError.unsupportedSchemaVersion(nil)
            }
            guard let version = value.int64Value else {
                throw CatalogDatabaseError.unsupportedSchemaVersion(nil)
            }
            return version
        }
    }

    public static func defaultDatabaseURL(fileManager: FileManager = .default) throws -> URL {
        guard let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw CatalogDatabaseError.sqlite(SQLITE_CANTOPEN, "Application Support directory is unavailable")
        }
        return applicationSupport.appendingPathComponent("FSD", isDirectory: true)
            .appendingPathComponent(defaultDatabaseFileName, isDirectory: false)
    }

    private func configureConnection() throws {
        try executeUnlocked("PRAGMA foreign_keys = ON")
        guard try scalarUnlocked("PRAGMA foreign_keys")?.int64Value == 1 else {
            throw CatalogDatabaseError.foreignKeysNotEnabled
        }
        try executeUnlocked("PRAGMA busy_timeout = 5000")
        try executeUnlocked("PRAGMA synchronous = NORMAL")
        try executeUnlocked("PRAGMA temp_store = MEMORY")
        try executeUnlocked("PRAGMA journal_mode = WAL")
        guard try scalarUnlocked("PRAGMA foreign_keys")?.int64Value == 1 else {
            throw CatalogDatabaseError.foreignKeysNotEnabled
        }
    }

    private func bootstrapIfNeeded(schemaURL: URL) throws {
        let hasMigrations = try scalarUnlocked(
            "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'schema_migrations' LIMIT 1"
        )?.int64Value == 1
        let hasUserTables = try scalarUnlocked(
            "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' LIMIT 1"
        )?.int64Value == 1

        if !hasMigrations {
            guard !hasUserTables else { throw CatalogDatabaseError.unsupportedSchemaVersion(nil) }
            try applySchema(from: schemaURL)
            try verifyCurrentSchemaState()
            return
        }

        let current = try scalarUnlocked("SELECT MAX(version) FROM schema_migrations")?.int64Value
        guard let current else { throw CatalogDatabaseError.unsupportedSchemaVersion(nil) }
        if current > Self.currentSchemaVersion {
            throw CatalogDatabaseError.unsupportedSchemaVersion(current)
        }
        if current < Self.currentSchemaVersion {
            // Versions 1-3 were never materialized and have no migration.
            guard current >= CatalogMigrations.oldestMigratableVersion else {
                throw CatalogDatabaseError.unsupportedSchemaVersion(current)
            }
            for migration in migrations.sorted(by: { $0.version < $1.version }) where migration.version > current {
                try apply(migration)
            }
            let migrated = try scalarUnlocked("SELECT MAX(version) FROM schema_migrations")?.int64Value
            guard migrated == Self.currentSchemaVersion else {
                throw CatalogDatabaseError.invalidSchemaVersion(migrated)
            }
        }
        try verifyCurrentSchemaState()
    }

    /// Applies one migration atomically. Every statement and the version row
    /// commit together or nothing does, so a failure leaves the recorded version
    /// exactly where it was and the next open retries from the same state.
    private func apply(_ migration: SchemaMigration) throws {
        try executeUnlocked("BEGIN IMMEDIATE")
        do {
            for statement in migration.statements {
                try executeScriptUnlocked(statement)
            }
            try executeUnlocked(
                "INSERT INTO schema_migrations(version, applied_at) VALUES (?, CURRENT_TIMESTAMP)",
                bindings: [.integer(migration.version)]
            )
            try executeUnlocked("COMMIT")
        } catch {
            _ = try? executeUnlocked("ROLLBACK")
            let message = (error as? CatalogDatabaseError)?.localizedDescription ?? error.localizedDescription
            throw CatalogDatabaseError.migrationFailed(migration.version, message)
        }
    }

    /// Confirms that a catalog reporting the current version really carries the
    /// current version's objects, whether it was created fresh or migrated.
    /// Version 4 could not do this — that was the drift — so the check is
    /// deliberately explicit rather than inferred from the version number.
    /// Triggers and indexes are compared against their canonical definitions,
    /// not just their names, so a substituted or materially altered
    /// safety-critical object is rejected the same way a missing one is.
    private func verifyCurrentSchemaState() throws {
        for table in CatalogMigrations.ExpectedState.tables {
            try requireSchemaObject(type: "table", name: table)
        }
        for entry in CatalogMigrations.ExpectedState.triggerDefinitions {
            try requireSchemaObject(type: "trigger", name: entry.name, canonicalSQL: entry.sql)
        }
        for entry in CatalogMigrations.ExpectedState.indexDefinitions {
            try requireSchemaObject(type: "index", name: entry.name, canonicalSQL: entry.sql)
        }
        for (table, columns) in [
            ("snapshots", CatalogMigrations.ExpectedState.snapshotColumns),
            ("comparisons", CatalogMigrations.ExpectedState.comparisonColumns),
            ("comparison_profiles", CatalogMigrations.ExpectedState.profileColumns),
            ("entry_classifications", CatalogMigrations.ExpectedState.classificationColumns)
        ] {
            for column in columns {
                let present = try scalarUnlocked(
                    "SELECT COUNT(*) FROM pragma_table_info('\(table)') WHERE name = ?",
                    bindings: [.text(column)]
                )?.int64Value ?? 0
                guard present == 1 else {
                    throw CatalogDatabaseError.schemaStateInvalid("missing \(table) column \(column)")
                }
            }
        }
    }

    private func requireSchemaObject(type: String, name: String) throws {
        let present = try scalarUnlocked(
            "SELECT COUNT(*) FROM sqlite_master WHERE type = ? AND name = ?",
            bindings: [.text(type), .text(name)]
        )?.int64Value ?? 0
        guard present == 1 else {
            throw CatalogDatabaseError.schemaStateInvalid("missing \(type) \(name)")
        }
    }

    /// Name plus definition: the stored object must exist AND its normalized
    /// DDL must match the canonical definition for the current version, so a
    /// same-name trigger or index with different semantics fails loudly.
    private func requireSchemaObject(type: String, name: String, canonicalSQL: String) throws {
        let stored = try scalarUnlocked(
            "SELECT sql FROM sqlite_master WHERE type = ? AND name = ?",
            bindings: [.text(type), .text(name)]
        )?.stringValue
        guard let stored else {
            throw CatalogDatabaseError.schemaStateInvalid("missing \(type) \(name)")
        }
        guard CatalogMigrations.ExpectedState.normalizedObjectSQL(stored)
                == CatalogMigrations.ExpectedState.normalizedObjectSQL(canonicalSQL) else {
            throw CatalogDatabaseError.schemaStateInvalid(
                "\(type) \(name) definition does not match schema version \(Self.currentSchemaVersion)"
            )
        }
    }

    private func applySchema(from schemaURL: URL) throws {
        guard FileManager.default.fileExists(atPath: schemaURL.path) else {
            throw CatalogDatabaseError.missingSchemaResource
        }
        let script: String
        do {
            script = try String(contentsOf: schemaURL, encoding: .utf8)
        } catch {
            throw CatalogDatabaseError.sqlite(SQLITE_ERROR, "Cannot read schema resource: \(error.localizedDescription)")
        }

        // Connection pragmas are applied before this transaction. SQLite does
        // not permit changing journal/safety settings while a transaction is
        // active, so the same pragmas in the canonical schema resource are
        // intentionally omitted from the transactional execution pass.
        let transactionalScript = script
            .replacingOccurrences(of: "PRAGMA foreign_keys = ON;", with: "")
            .replacingOccurrences(of: "PRAGMA journal_mode = WAL;", with: "")
            .replacingOccurrences(of: "PRAGMA synchronous = NORMAL;", with: "")

        try executeUnlocked("BEGIN IMMEDIATE")
        do {
            try executeScriptUnlocked(transactionalScript)
            let version = try scalarUnlocked("SELECT MAX(version) FROM schema_migrations")?.int64Value
            guard version == Self.currentSchemaVersion else {
                throw CatalogDatabaseError.invalidSchemaVersion(version)
            }
            try executeUnlocked("COMMIT")
        } catch {
            _ = try? executeUnlocked("ROLLBACK")
            throw error
        }
    }

    private func executeScriptUnlocked(_ script: String) throws {
        guard let handle else { throw CatalogDatabaseError.sqlite(SQLITE_MISUSE, "Database is closed") }
        var errorMessage: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(handle, script, nil, nil, &errorMessage)
        guard result == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? String(cString: sqlite3_errmsg(handle))
            if let errorMessage { sqlite3_free(errorMessage) }
            throw CatalogDatabaseError.sqlite(result, message)
        }
    }

    private func executeUnlocked(_ sql: String, bindings: [DatabaseValue] = []) throws {
        guard let handle else { throw CatalogDatabaseError.sqlite(SQLITE_MISUSE, "Database is closed") }
        let statement = try prepare(sql, handle: handle)
        defer { sqlite3_finalize(statement) }
        try bind(bindings, to: statement)

        while true {
            let stepResult = sqlite3_step(statement)
            if stepResult == SQLITE_DONE { return }
            if stepResult != SQLITE_ROW { throw sqliteError(code: stepResult, handle: handle) }
        }
    }

    private func scalarUnlocked(_ sql: String, bindings: [DatabaseValue] = []) throws -> DatabaseValue? {
        guard let handle else { throw CatalogDatabaseError.sqlite(SQLITE_MISUSE, "Database is closed") }
        let statement = try prepare(sql, handle: handle)
        defer { sqlite3_finalize(statement) }
        try bind(bindings, to: statement)
        let stepResult = sqlite3_step(statement)
        if stepResult == SQLITE_ROW { return value(from: statement, column: 0) }
        if stepResult == SQLITE_DONE { return nil }
        throw sqliteError(code: stepResult, handle: handle)
    }

    private func prepare(_ sql: String, handle: OpaquePointer) throws -> OpaquePointer {
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(handle, sql, -1, &statement, nil)
        guard result == SQLITE_OK, let statement else {
            throw sqliteError(code: result, handle: handle)
        }
        return statement
    }

    private func bind(_ values: [DatabaseValue], to statement: OpaquePointer) throws {
        for (offset, value) in values.enumerated() {
            let index = Int32(offset + 1)
            let result: Int32
            switch value {
            case .null:
                result = sqlite3_bind_null(statement, index)
            case let .integer(number):
                result = sqlite3_bind_int64(statement, index, number)
            case let .real(number):
                result = sqlite3_bind_double(statement, index, number)
            case let .text(string):
                result = string.withCString { pointer in
                    sqlite3_bind_text(statement, index, pointer, -1, CatalogDatabase.sqliteTransient)
                }
            case let .blob(data):
                result = data.withUnsafeBytes { bytes in
                    sqlite3_bind_blob(statement, index, bytes.baseAddress, Int32(data.count), CatalogDatabase.sqliteTransient)
                }
            }
            guard result == SQLITE_OK else {
                throw CatalogDatabaseError.sqlite(result, "Failed to bind SQLite parameter \(index)")
            }
        }
    }

    private func value(from statement: OpaquePointer, column: Int32) -> DatabaseValue {
        switch sqlite3_column_type(statement, column) {
        case SQLITE_INTEGER:
            return .integer(sqlite3_column_int64(statement, column))
        case SQLITE_FLOAT:
            return .real(sqlite3_column_double(statement, column))
        case SQLITE_TEXT:
            return .text(String(cString: sqlite3_column_text(statement, column)))
        case SQLITE_BLOB:
            let length = Int(sqlite3_column_bytes(statement, column))
            guard let bytes = sqlite3_column_blob(statement, column), length > 0 else { return .blob(Data()) }
            return .blob(Data(bytes: bytes, count: length))
        default:
            return .null
        }
    }

    private func sqliteError(code: Int32, handle: OpaquePointer) -> CatalogDatabaseError {
        .sqlite(code, String(cString: sqlite3_errmsg(handle)))
    }

    private func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }

    private static func bundledSchemaURL() throws -> URL {
        if let url = Bundle.main.url(forResource: "schema", withExtension: "sql") { return url }
        if let url = Bundle(for: CatalogDatabase.self).url(forResource: "schema", withExtension: "sql") { return url }
        throw CatalogDatabaseError.missingSchemaResource
    }

    private static let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
}
