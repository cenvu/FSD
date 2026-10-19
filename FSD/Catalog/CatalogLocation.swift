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
        /// `~/Library/Application Support/FSD-Internal-Preview/catalog.sqlite3` —
        /// the dedicated Internal Preview catalog. Never the production catalog.
        case internalPreview
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

    /// True only when this process resolved the dedicated Internal Preview
    /// catalog. The UI uses this to show the explicit Internal Preview marker.
    public var isInternalPreview: Bool { origin == .internalPreview }

    /// One line, printed at startup and shown in the app's diagnostics, so an
    /// operator or an automated probe can see which catalog is actually in use.
    public var diagnosticLine: String {
        var line = isInternalPreview
            ? "FSD Internal Preview catalog: \(url.path) (source: \(origin.rawValue))"
            : "FSD catalog: \(url.path) (source: \(origin.rawValue))"
        if let rejectedOverridePath {
            line += " — override request \(rejectedOverridePath.debugDescription) ignored: "
            if origin == .testHost {
                line += "an XCTest host always uses its own isolated catalog"
            } else if isInternalPreview {
                line += "the Internal Preview always uses its dedicated catalog"
            } else {
                line += "catalog-path overrides are available in DEBUG builds only"
            }
        }
        return line
    }
}

public enum CatalogLocationError: Error, LocalizedError, Equatable {
    case applicationSupportUnavailable
    case internalPreviewUnavailable
    case internalPreviewConflictsWithProduction
    case emptyOverridePath

    public var errorDescription: String? {
        switch self {
        case .applicationSupportUnavailable:
            return "The Application Support directory is unavailable, so the catalog location cannot be resolved."
        case .internalPreviewUnavailable:
            return "The Application Support directory is unavailable, so the Internal Preview catalog location cannot be resolved. The Internal Preview never falls back to the production catalog."
        case .internalPreviewConflictsWithProduction:
            return "The Internal Preview catalog location resolves onto the production FSD catalog, so the Internal Preview refuses to start. The Internal Preview never opens the production catalog."
        case .emptyOverridePath:
            return "The requested catalog path override is empty."
        }
    }
}

public enum CatalogLocationResolver {
    public static let launchArgumentName = "-FSDCatalogPath"
    public static let environmentVariableName = "FSD_CATALOG_PATH"

    /// The production catalog directory under Application Support.
    public static let productionDirectoryName = "FSD"

    /// The Internal Preview stores its catalog in its own Application Support
    /// directory, so it can never open, migrate or lock the production catalog.
    public static let internalPreviewDirectoryName = "FSD-Internal-Preview"

    /// Which catalog the compiled product resolves. The Internal Preview flavor
    /// is selected at compile time so a stray runtime flag can never move a
    /// production build onto the preview catalog, or the preview onto the
    /// production catalog.
    public enum Flavor: String, Sendable {
        /// The shipping FishSock Differ product: production Application Support.
        case production
        /// The isolated FSD2 Internal Preview: its own dedicated catalog only.
        case internalPreview

        public static var buildTime: Flavor {
            #if FSD_INTERNAL_PREVIEW
            return .internalPreview
            #else
            return .production
            #endif
        }
    }

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
        overrideAllowed: Bool = overrideIsAvailable,
        flavor: Flavor = Flavor.buildTime
    ) throws -> CatalogLocation {
        let requested = requestedOverride(arguments: arguments, environment: environment)

        // Internal Preview flavor. It resolves only its dedicated catalog and
        // never consults the production path. The XCTest host still gets its own
        // isolated synthetic catalog so automated runs never touch preview data.
        //
        // There is deliberately no runtime catalog override in this flavor: no
        // launch argument, environment variable, test seam or symlink may move
        // the compiled preview onto an arbitrary path — in particular onto the
        // production catalog. `internalPreviewURL` fails closed if the preview
        // location aliases the production location.
        if flavor == .internalPreview {
            if isRunningAsTestHost(environment: environment) {
                return CatalogLocation(
                    url: testHostCatalogURL(),
                    origin: .testHost,
                    rejectedOverridePath: requested?.path
                )
            }
            return CatalogLocation(
                url: try internalPreviewURL(fileManager: fileManager),
                origin: .internalPreview,
                rejectedOverridePath: requested?.path
            )
        }

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
            .appendingPathComponent(productionDirectoryName, isDirectory: true)
            .appendingPathComponent(CatalogDatabase.defaultDatabaseFileName, isDirectory: false)
    }

    /// The Internal Preview's dedicated catalog. There is intentionally no
    /// fallback to the production `FSD/catalog.sqlite3` path: if the Application
    /// Support directory cannot be resolved the preview fails loudly instead.
    ///
    /// The location is also verified against the production location after
    /// resolving symbolic links, so a symlinked `FSD-Internal-Preview` directory
    /// (or catalog file) that aliases the production catalog fails closed instead
    /// of opening production data.
    public static func internalPreviewURL(fileManager: FileManager = .default) throws -> URL {
        guard let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw CatalogLocationError.internalPreviewUnavailable
        }
        let previewDirectory = applicationSupport
            .appendingPathComponent(internalPreviewDirectoryName, isDirectory: true)
        let previewURL = previewDirectory
            .appendingPathComponent(CatalogDatabase.defaultDatabaseFileName, isDirectory: false)
        let productionDirectory = applicationSupport
            .appendingPathComponent(productionDirectoryName, isDirectory: true)
        let productionURL = productionDirectory
            .appendingPathComponent(CatalogDatabase.defaultDatabaseFileName, isDirectory: false)
        if canonicalPath(previewDirectory) == canonicalPath(productionDirectory)
            || canonicalPath(previewURL) == canonicalPath(productionURL) {
            throw CatalogLocationError.internalPreviewConflictsWithProduction
        }
        return previewURL
    }

    /// A symlink-resolved, standardised path used only for the fail-closed
    /// comparison between the preview and production locations.
    private static func canonicalPath(_ url: URL) -> String {
        url.resolvingSymlinksInPath().standardizedFileURL.path
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
