import Foundation

/// Where the catalog lives for this process, and why.
///
/// Condition C6 of the Milestone 2 acceptance audit: the catalog path was fixed
/// to Application Support, and macOS resolves `NSHomeDirectory()` from the user
/// record rather than `$HOME`, so no isolated catalog could be created for
/// testing or for an automated acceptance probe. Every automated run would have
/// had to share the project owner's real catalog.
public struct CatalogLocation: Equatable, Sendable {
    public enum Origin: String, Sendable {
        /// `~/Library/Application Support/FSD/catalog.sqlite3` — the production default.
        case applicationSupport
        /// `-FSDCatalogPath <path>` on the command line.
        case launchArgument
        /// `FSD_CATALOG_PATH` in the environment.
        case environment
        /// The process is hosting an XCTest bundle. FSD's unit tests run inside
        /// the real application, so without this the test host would open — and
        /// migrate, and lock — the person's actual catalog on every run.
        case testHost
        /// Supplied directly in code. Used by tests, never by the shipping app.
        case injected
    }

    public let url: URL
    public let origin: Origin
    /// Set when an override was requested but this build does not honour
    /// overrides. The request is reported rather than silently dropped.
    public let rejectedOverridePath: String?

    public init(url: URL, origin: Origin, rejectedOverridePath: String? = nil) {
        self.url = url
        self.origin = origin
        self.rejectedOverridePath = rejectedOverridePath
    }

    public var isOverridden: Bool { origin != .applicationSupport }

    /// One line, printed at startup and shown in the app's diagnostics, so an
    /// operator or an automated probe can see which catalog is actually in use.
    public var diagnosticLine: String {
        var line = "FSD catalog: \(url.path) (source: \(origin.rawValue))"
        if let rejectedOverridePath {
            line += " — override request \(rejectedOverridePath.debugDescription) ignored: "
            line += origin == .testHost
                ? "an XCTest host always uses its own isolated catalog"
                : "catalog-path overrides are available in DEBUG builds only"
        }
        return line
    }
}

public enum CatalogLocationError: Error, LocalizedError, Equatable {
    case applicationSupportUnavailable
    case emptyOverridePath

    public var errorDescription: String? {
        switch self {
        case .applicationSupportUnavailable:
            return "The Application Support directory is unavailable, so the catalog location cannot be resolved."
        case .emptyOverridePath:
            return "The requested catalog path override is empty."
        }
    }
}

public enum CatalogLocationResolver {
    public static let launchArgumentName = "-FSDCatalogPath"
    public static let environmentVariableName = "FSD_CATALOG_PATH"

    /// Overrides are a development and test affordance. A Release build resolves
    /// the Application Support default unconditionally and reports the ignored
    /// request, so a stray argument or a stale environment variable can never
    /// silently redirect a real user's catalog to an arbitrary path.
    public static var overrideIsAvailable: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    /// - Parameter overrideAllowed: defaults to `overrideIsAvailable`. Passed
    ///   explicitly by tests so both the honoured and the refused branch are
    ///   exercised from one build.
    public static func resolve(
        arguments: [String] = CommandLine.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default,
        overrideAllowed: Bool = overrideIsAvailable
    ) throws -> CatalogLocation {
        let requested = requestedOverride(arguments: arguments, environment: environment)
        if let requested, overrideAllowed {
            let trimmed = requested.path.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { throw CatalogLocationError.emptyOverridePath }
            return CatalogLocation(url: catalogURL(forOverridePath: trimmed), origin: requested.origin)
        }
        // The test target's host is the FSD application itself, so launching the
        // test bundle starts a full `ApplicationModel`. Without this branch that
        // model would open the person's real catalog, migrate it, and hold the
        // process lock on it for the duration of every test run. An automated
        // run must never reach a real catalog, so the test host gets its own.
        if isRunningAsTestHost(environment: environment) {
            return CatalogLocation(
                url: testHostCatalogURL(),
                origin: .testHost,
                rejectedOverridePath: requested?.path
            )
        }
        guard let requested else {
            return CatalogLocation(url: try defaultURL(fileManager: fileManager), origin: .applicationSupport)
        }
        guard overrideAllowed else {
            return CatalogLocation(
                url: try defaultURL(fileManager: fileManager),
                origin: .applicationSupport,
                rejectedOverridePath: requested.path
            )
        }
        let trimmed = requested.path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CatalogLocationError.emptyOverridePath }
        return CatalogLocation(url: catalogURL(forOverridePath: trimmed), origin: requested.origin)
    }

    /// An override may name the database file itself or the directory to hold it.
    /// A path ending in the catalog file extension is taken literally; anything
    /// else is treated as a directory and the default file name is appended.
    public static func catalogURL(forOverridePath path: String) -> URL {
        let expanded = (path as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)
        if url.pathExtension.lowercased() == "sqlite3" { return url }
        return url.appendingPathComponent(CatalogDatabase.defaultDatabaseFileName, isDirectory: false)
    }

    /// Set by XCTest in the host process it injects into.
    public static let testHostEnvironmentKeys = ["XCTestConfigurationFilePath", "XCTestBundlePath", "XCTestSessionIdentifier"]

    public static func isRunningAsTestHost(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Bool {
        testHostEnvironmentKeys.contains { environment[$0]?.isEmpty == false }
    }

    /// One catalog per test-host process, so concurrent runs never contend for
    /// the same catalog lock and nothing survives to affect the next run.
    public static func testHostCatalogURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("FSD-TestHost-\(ProcessInfo.processInfo.processIdentifier)", isDirectory: true)
            .appendingPathComponent(CatalogDatabase.defaultDatabaseFileName, isDirectory: false)
    }

    public static func defaultURL(fileManager: FileManager = .default) throws -> URL {
        guard let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw CatalogLocationError.applicationSupportUnavailable
        }
        return applicationSupport
            .appendingPathComponent("FSD", isDirectory: true)
            .appendingPathComponent(CatalogDatabase.defaultDatabaseFileName, isDirectory: false)
    }

    private static func requestedOverride(
        arguments: [String],
        environment: [String: String]
    ) -> (path: String, origin: CatalogLocation.Origin)? {
        if let index = arguments.firstIndex(of: launchArgumentName), index + 1 < arguments.count {
            let value = arguments[index + 1]
            if !value.isEmpty { return (value, .launchArgument) }
        }
        if let value = environment[environmentVariableName], !value.isEmpty {
            return (value, .environment)
        }
        return nil
    }
}
