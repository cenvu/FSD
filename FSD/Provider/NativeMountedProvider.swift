import Darwin
import Foundation
import UniformTypeIdentifiers

public final class NativeMountedProvider: FilesystemProvider {
    /// Message recorded for every mount boundary that is deliberately not
    /// descended into. Stable text so the UI and tests can recognise it.
    public static let mountBoundaryMessage =
        "A different filesystem is mounted here. Its contents are outside this capture and were not enumerated."

    public static let currentProviderVersion = "native/FileManager-m3"

    public let descriptor: FilesystemDescriptor
    public let providerVersion = NativeMountedProvider.currentProviderVersion

    private let fileManager: FileManager
    private let deviceProbe: DeviceIdentityProbe
    private let keys: [URLResourceKey] = [
        .isDirectoryKey, .isSymbolicLinkKey, .isPackageKey, .isHiddenKey,
        .fileSizeKey, .fileAllocatedSizeKey, .creationDateKey,
        .contentModificationDateKey, .contentTypeKey, .fileResourceIdentifierKey
    ]

    public init(
        descriptor: FilesystemDescriptor,
        fileManager: FileManager = .default,
        deviceProbe: DeviceIdentityProbe = POSIXDeviceIdentityProbe()
    ) {
        self.descriptor = descriptor
        self.fileManager = fileManager
        self.deviceProbe = deviceProbe
    }

    public func enumerate(
        onEntry: @escaping (MetadataEntry) throws -> Void,
        onIssue: @escaping (ScanIssue) throws -> Void,
        onProgress: (EnumerationProgress) -> Void,
        isCancelled: () -> Bool
    ) throws -> EnumerationResult {
        let root = descriptor.rootURL
        guard fileManager.fileExists(atPath: root.path) else {
            throw FilesystemProviderError.invalidSource(root.path)
        }
        var processed: Int64 = 0
        var issues: Int64 = 0
        // The selected root's filesystem identity. Every directory encountered
        // below it is compared against this; a mismatch is a mount boundary.
        // If the root's own identity cannot be read, the guard reports nothing
        // rather than guessing — it never invents a boundary it did not observe.
        let rootDevice = try? deviceProbe.deviceIdentifier(atPath: root.path)
        _ = try emit(url: root, relativePath: "", onEntry: onEntry, onIssue: onIssue, issueCount: &issues)
        processed = 1
        onProgress(EnumerationProgress(processedEntries: processed, currentPath: ""))

        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: keys,
            options: [],
            errorHandler: { [weak self] url, error in
                _ = self
                issues += 1
                try? onIssue(ScanIssue(
                    relativePath: self?.relativePath(for: url) ?? url.lastPathComponent,
                    errorDomain: (error as NSError).domain,
                    errorCode: Int32((error as NSError).code),
                    message: error.localizedDescription,
                    wasSkipped: true
                ))
                return true
            }
        ) else {
            throw FilesystemProviderError.invalidSource("The selected folder cannot be enumerated.")
        }

        for case let url as URL in enumerator {
            if isCancelled() {
                return EnumerationResult(processedEntries: processed, issueCount: issues, wasCancelled: true)
            }
            guard isWithinRoot(url) else {
                throw FilesystemProviderError.outsideSelectedRoot(url.path)
            }
            let relativePath = relativePath(for: url)
            do {
                let entry = try emit(
                    url: url, relativePath: relativePath,
                    onEntry: onEntry, onIssue: onIssue, issueCount: &issues
                )
                // `skipDescendants()` skips "the most recently obtained
                // subdirectory". A symlink is not a subdirectory, and calling it
                // there made the enumerator skip descent into the NEXT directory
                // at the same level instead — silently dropping that whole
                // subtree from the snapshot with no scan issue. The call was
                // never needed: `FileManager.enumerator` does not follow a
                // symlink to a directory in the first place (verified), so a
                // symlink is recorded and left alone with no action here.
                if entry.itemKind == .package {
                    enumerator.skipDescendants()
                } else if entry.itemKind == .directory,
                          crossesMountBoundary(url, rootDevice: rootDevice) {
                    // The mount point itself is already recorded above as
                    // metadata. What is refused is descent into the other
                    // filesystem, and the bounded issue below keeps the skipped
                    // subtree from reading as "enumerated and empty".
                    issues += 1
                    try onIssue(ScanIssue(
                        relativePath: relativePath,
                        severity: "warning",
                        message: Self.mountBoundaryMessage,
                        wasSkipped: true
                    ))
                    enumerator.skipDescendants()
                }
            } catch let error as FilesystemProviderError {
                throw error
            } catch {
                issues += 1
                try onIssue(ScanIssue(
                    relativePath: relativePath,
                    errorDomain: (error as NSError).domain,
                    errorCode: Int32((error as NSError).code),
                    message: error.localizedDescription,
                    wasSkipped: false
                ))
            }
            processed += 1
            if processed % 64 == 0 {
                onProgress(EnumerationProgress(processedEntries: processed, currentPath: relativePath))
            }
        }
        onProgress(EnumerationProgress(processedEntries: processed, currentPath: ""))
        return EnumerationResult(processedEntries: processed, issueCount: issues, wasCancelled: false)
    }

    private func emit(
        url: URL,
        relativePath: String,
        onEntry: (MetadataEntry) throws -> Void,
        onIssue: (ScanIssue) throws -> Void,
        issueCount: inout Int64
    ) throws -> MetadataEntry {
        let name = relativePath.isEmpty ? (url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent) : url.lastPathComponent
        let parent = relativePath.isEmpty ? nil : parentPath(of: relativePath)
        let pathIdentity = PathIdentity.path(relativePath)
        let nameIdentity = PathIdentity.path(name)
        var values = URLResourceValues()
        var issue: ScanIssue?
        do {
            values = try url.resourceValues(forKeys: Set(keys))
        } catch {
            issue = ScanIssue(
                relativePath: relativePath,
                errorDomain: (error as NSError).domain,
                errorCode: Int32((error as NSError).code),
                message: error.localizedDescription,
                wasSkipped: false
            )
            issueCount += 1
        }
        let symbolicLink = values.isSymbolicLink ?? isSymbolicLink(url)
        let directory = values.isDirectory ?? false
        let package = values.isPackage ?? false
        let itemKind: FilesystemItemKind
        if symbolicLink { itemKind = .symlink }
        else if package { itemKind = .package }
        else if directory { itemKind = .directory }
        else if values.fileSize != nil || !url.hasDirectoryPath { itemKind = .file }
        else { itemKind = .other }
        let symlinkTarget = symbolicLink ? try? fileManager.destinationOfSymbolicLink(atPath: url.path) : nil
        let entry = MetadataEntry(
            relativePath: relativePath,
            parentRelativePath: parent,
            name: name,
            casePreservingPath: pathIdentity.preserving,
            caseFoldedPath: pathIdentity.folded,
            casePreservingName: nameIdentity.preserving,
            caseFoldedName: nameIdentity.folded,
            fileExtension: url.pathExtension.isEmpty ? nil : url.pathExtension,
            itemKind: itemKind,
            logicalSizeBytes: values.fileSize.map(Int64.init),
            allocatedSizeBytes: values.fileAllocatedSize.map(Int64.init),
            createdAt: values.creationDate,
            modifiedAt: values.contentModificationDate,
            contentTypeIdentifier: values.contentType?.identifier,
            resourceIdentifier: values.fileResourceIdentifier as? Data,
            symlinkTarget: symlinkTarget,
            isHidden: values.isHidden ?? url.lastPathComponent.hasPrefix("."),
            isPackage: package,
            isInaccessible: issue != nil,
            sortKey: pathIdentity.folded
        )
        try onEntry(entry)
        if let issue { try onIssue(issue) }
        return entry
    }

    private func relativePath(for url: URL) -> String {
        let rootPath = lexicalPath(descriptor.rootURL.path)
        let candidatePath = lexicalPath(url.path)
        guard candidatePath != rootPath else { return "" }
        let prefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
        return String(candidatePath.dropFirst(prefix.count))
    }

    /// True when `url` sits on a filesystem other than the selected root's.
    /// Mount handling is kept entirely separate from symlink handling: this
    /// never follows a link, and a symlink is classified before it is reached.
    private func crossesMountBoundary(_ url: URL, rootDevice: dev_t?) -> Bool {
        guard let rootDevice else { return false }
        guard let device = try? deviceProbe.deviceIdentifier(atPath: url.path) else { return false }
        return device != rootDevice
    }

    private func isWithinRoot(_ url: URL) -> Bool {
        let canonicalRoot = lexicalPath(descriptor.rootURL.path)
        let rootPath = canonicalRoot.hasSuffix("/") ? canonicalRoot : canonicalRoot + "/"
        let candidate = lexicalPath(url.path)
        return candidate == canonicalRoot || candidate.hasPrefix(rootPath)
    }

    private func parentPath(of relativePath: String) -> String {
        guard let slash = relativePath.lastIndex(of: "/") else { return "" }
        return String(relativePath[..<slash])
    }

    private func isSymbolicLink(_ url: URL) -> Bool {
        var info = stat()
        return lstat(url.path, &info) == 0 && (info.st_mode & S_IFMT) == S_IFLNK
    }

    private func lexicalPath(_ path: String) -> String {
        let standardized = URL(fileURLWithPath: path).standardizedFileURL.path
        return standardized.hasPrefix("/private/") ? String(standardized.dropFirst("/private".count)) : standardized
    }
}
