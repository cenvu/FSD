import Darwin
import Foundation

public enum FilesystemItemKind: String, Codable, Sendable {
    case directory
    case file
    case symlink
    case package
    case other
}

public struct FilesystemCapabilities: Codable, Sendable, Equatable {
    public let supportsAllocatedSize: Bool
    public let supportsCreationDate: Bool
    public let supportsModificationDate: Bool
    public let supportsContentType: Bool

    public init(
        supportsAllocatedSize: Bool = true,
        supportsCreationDate: Bool = true,
        supportsModificationDate: Bool = true,
        supportsContentType: Bool = true
    ) {
        self.supportsAllocatedSize = supportsAllocatedSize
        self.supportsCreationDate = supportsCreationDate
        self.supportsModificationDate = supportsModificationDate
        self.supportsContentType = supportsContentType
    }
}

public struct FilesystemDescriptor: Codable, Sendable, Equatable {
    public let rootURL: URL
    public let volumeName: String
    public let volumeIdentifier: String
    public let filesystemType: String
    public let sourceCaseSensitivity: SourceCaseSensitivity
    public let isReadOnly: Bool
    public let mountPath: String
    public let capacityBytes: Int64?
    public let availableBytes: Int64?
    public let capabilities: FilesystemCapabilities

    public init(
        rootURL: URL,
        volumeName: String,
        volumeIdentifier: String,
        filesystemType: String,
        sourceCaseSensitivity: SourceCaseSensitivity,
        isReadOnly: Bool,
        mountPath: String,
        capacityBytes: Int64?,
        availableBytes: Int64?,
        capabilities: FilesystemCapabilities = FilesystemCapabilities()
    ) {
        self.rootURL = rootURL
        self.volumeName = volumeName
        self.volumeIdentifier = volumeIdentifier
        self.filesystemType = filesystemType
        self.sourceCaseSensitivity = sourceCaseSensitivity
        self.isReadOnly = isReadOnly
        self.mountPath = mountPath
        self.capacityBytes = capacityBytes
        self.availableBytes = availableBytes
        self.capabilities = capabilities
    }
}

public struct MetadataEntry: Codable, Sendable, Equatable {
    public let relativePath: String
    public let parentRelativePath: String?
    public let name: String
    public let casePreservingPath: String
    public let caseFoldedPath: String
    public let casePreservingName: String
    public let caseFoldedName: String
    public let fileExtension: String?
    public let itemKind: FilesystemItemKind
    public let logicalSizeBytes: Int64?
    public let allocatedSizeBytes: Int64?
    public let createdAt: Date?
    public let modifiedAt: Date?
    public let contentTypeIdentifier: String?
    public let resourceIdentifier: Data?
    public let symlinkTarget: String?
    public let isHidden: Bool
    public let isPackage: Bool
    public let isInaccessible: Bool
    public let sortKey: String

    public init(
        relativePath: String,
        parentRelativePath: String?,
        name: String,
        casePreservingPath: String,
        caseFoldedPath: String,
        casePreservingName: String,
        caseFoldedName: String,
        fileExtension: String?,
        itemKind: FilesystemItemKind,
        logicalSizeBytes: Int64?,
        allocatedSizeBytes: Int64?,
        createdAt: Date?,
        modifiedAt: Date?,
        contentTypeIdentifier: String?,
        resourceIdentifier: Data?,
        symlinkTarget: String?,
        isHidden: Bool,
        isPackage: Bool,
        isInaccessible: Bool,
        sortKey: String
    ) {
        self.relativePath = relativePath
        self.parentRelativePath = parentRelativePath
        self.name = name
        self.casePreservingPath = casePreservingPath
        self.caseFoldedPath = caseFoldedPath
        self.casePreservingName = casePreservingName
        self.caseFoldedName = caseFoldedName
        self.fileExtension = fileExtension
        self.itemKind = itemKind
        self.logicalSizeBytes = logicalSizeBytes
        self.allocatedSizeBytes = allocatedSizeBytes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.contentTypeIdentifier = contentTypeIdentifier
        self.resourceIdentifier = resourceIdentifier
        self.symlinkTarget = symlinkTarget
        self.isHidden = isHidden
        self.isPackage = isPackage
        self.isInaccessible = isInaccessible
        self.sortKey = sortKey
    }

    public static func root(name: String) -> MetadataEntry {
        MetadataEntry(
            relativePath: "", parentRelativePath: nil, name: name,
            casePreservingPath: "", caseFoldedPath: "",
            casePreservingName: name,
            caseFoldedName: PathIdentity.caseFold(name),
            fileExtension: nil, itemKind: .directory,
            logicalSizeBytes: nil, allocatedSizeBytes: nil,
            createdAt: nil, modifiedAt: nil, contentTypeIdentifier: nil,
            resourceIdentifier: nil, symlinkTarget: nil,
            isHidden: false, isPackage: false, isInaccessible: false,
            sortKey: "0"
        )
    }
}

public struct ScanIssue: Codable, Sendable, Equatable {
    public let relativePath: String
    public let errorDomain: String?
    public let errorCode: Int32?
    public let severity: String
    public let source: String
    public let message: String
    public let wasSkipped: Bool

    public init(
        relativePath: String,
        errorDomain: String? = nil,
        errorCode: Int32? = nil,
        severity: String = "warning",
        source: String = "scanner",
        message: String,
        wasSkipped: Bool = false
    ) {
        self.relativePath = relativePath
        self.errorDomain = errorDomain
        self.errorCode = errorCode
        self.severity = severity
        self.source = source
        self.message = message
        self.wasSkipped = wasSkipped
    }
}

public struct EnumerationProgress: Sendable, Equatable {
    public let processedEntries: Int64
    public let currentPath: String

    public init(processedEntries: Int64, currentPath: String) {
        self.processedEntries = processedEntries
        self.currentPath = currentPath
    }
}

public struct EnumerationResult: Sendable, Equatable {
    public let processedEntries: Int64
    public let issueCount: Int64
    public let wasCancelled: Bool

    public init(processedEntries: Int64, issueCount: Int64, wasCancelled: Bool) {
        self.processedEntries = processedEntries
        self.issueCount = issueCount
        self.wasCancelled = wasCancelled
    }
}

public enum FilesystemProviderError: Error, LocalizedError, Equatable {
    case invalidSource(String)
    case metadataUnavailable(String)
    case outsideSelectedRoot(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case let .invalidSource(message): return "Invalid capture source: \(message)"
        case let .metadataUnavailable(message): return "Filesystem metadata unavailable: \(message)"
        case let .outsideSelectedRoot(path): return "Entry escaped the selected root: \(path)"
        case .cancelled: return "Filesystem enumeration was cancelled."
        }
    }
}

/// Reads the filesystem identity of a path without following symbolic links.
///
/// Condition C3 of the Milestone 2 acceptance audit: a filesystem mounted below
/// the selected root was empirically not descended into, but only because
/// `FileManager.enumerator` happens to behave that way. FSD had no guard of its
/// own, and recorded the mount point as an ordinary empty directory with no
/// scan issue — presenting a subtree that was never enumerated as if it had been
/// enumerated and found empty. This protocol makes the boundary explicit and
/// testable without requiring a real mount.
///
/// Metadata only: `lstat` reads the inode, never file contents, and never
/// resolves a symlink, so mount handling stays independent of symlink handling.
public protocol DeviceIdentityProbe: Sendable {
    func deviceIdentifier(atPath path: String) throws -> dev_t
}

public struct POSIXDeviceIdentityProbe: DeviceIdentityProbe {
    public init() {}

    public func deviceIdentifier(atPath path: String) throws -> dev_t {
        var info = stat()
        guard lstat(path, &info) == 0 else {
            throw FilesystemProviderError.metadataUnavailable(
                "\(path): \(String(cString: strerror(errno)))"
            )
        }
        return info.st_dev
    }
}

public protocol FilesystemProvider {
    var descriptor: FilesystemDescriptor { get }
    var providerVersion: String { get }

    func enumerate(
        onEntry: @escaping (MetadataEntry) throws -> Void,
        onIssue: @escaping (ScanIssue) throws -> Void,
        onProgress: (EnumerationProgress) -> Void,
        isCancelled: () -> Bool
    ) throws -> EnumerationResult
}

public enum PathIdentity {
    public static let normalizationVersion = NormalizationVersion.current

    public static func casePreserving(_ value: String) -> String {
        value.precomposedStringWithCanonicalMapping
    }

    public static func caseFold(_ value: String) -> String {
        value.folding(options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .precomposedStringWithCanonicalMapping
    }

    public static func path(_ value: String) -> (preserving: String, folded: String) {
        (casePreserving(value), caseFold(value))
    }
}
