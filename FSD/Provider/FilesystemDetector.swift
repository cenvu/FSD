import Darwin
import Foundation

public enum FilesystemDetectorError: Error, LocalizedError, Equatable {
    case sourceDoesNotExist(String)
    case sourceIsNotDirectory(String)
    case cannotReadMetadata(String)

    public var errorDescription: String? {
        switch self {
        case let .sourceDoesNotExist(path): return "Capture source does not exist: \(path)"
        case let .sourceIsNotDirectory(path): return "Capture source is not a folder or volume root: \(path)"
        case let .cannotReadMetadata(message): return "Cannot detect filesystem metadata: \(message)"
        }
    }
}

public struct FilesystemDetector {
    public init() {}

    public func detect(root: URL) throws -> FilesystemDescriptor {
        // Resolve only the selected root's mount alias (for example /var ->
        // /private/var). Entry URLs remain lexical so symlink destinations are
        // never resolved or traversed by the provider.
        let selectedRoot = root.standardizedFileURL.resolvingSymlinksInPath()
        guard FileManager.default.fileExists(atPath: selectedRoot.path) else {
            throw FilesystemDetectorError.sourceDoesNotExist(selectedRoot.path)
        }
        let values: URLResourceValues
        do {
            values = try selectedRoot.resourceValues(forKeys: [
                .isDirectoryKey, .isSymbolicLinkKey, .volumeNameKey, .volumeUUIDStringKey,
                .volumeSupportsCaseSensitiveNamesKey, .volumeIsReadOnlyKey,
                .volumeTotalCapacityKey, .volumeAvailableCapacityKey, .fileResourceIdentifierKey
            ])
        } catch {
            throw FilesystemDetectorError.cannotReadMetadata(error.localizedDescription)
        }
        guard values.isDirectory == true, values.isSymbolicLink != true else {
            throw FilesystemDetectorError.sourceIsNotDirectory(selectedRoot.path)
        }

        let volumeValues = values
        let stat = try statfsMetadata(for: selectedRoot.path)
        let volumeID = volumeValues.volumeUUIDString ?? volumeValues.fileResourceIdentifier.map(String.init(describing:))
            ?? "native-root:\(stat.mountPath)"
        let caseSensitivity: SourceCaseSensitivity
        if let supportsCaseSensitive = values.volumeSupportsCaseSensitiveNames {
            caseSensitivity = supportsCaseSensitive ? .sensitive : .insensitive
        } else {
            caseSensitivity = .unknown
        }
        return FilesystemDescriptor(
            rootURL: selectedRoot,
            volumeName: volumeValues.volumeName ?? selectedRoot.lastPathComponent,
            volumeIdentifier: volumeID,
            filesystemType: stat.filesystemType,
            sourceCaseSensitivity: caseSensitivity,
            isReadOnly: volumeValues.volumeIsReadOnly ?? stat.isReadOnly,
            mountPath: stat.mountPath,
            capacityBytes: volumeValues.volumeTotalCapacity.map(Int64.init),
            availableBytes: volumeValues.volumeAvailableCapacity.map(Int64.init),
            capabilities: FilesystemCapabilities()
        )
    }

    private func statfsMetadata(for path: String) throws -> (filesystemType: String, mountPath: String, isReadOnly: Bool) {
        var buffer = statfs()
        guard statfs(path, &buffer) == 0 else {
            throw FilesystemDetectorError.cannotReadMetadata(String(cString: strerror(errno)))
        }
        var filesystemTypeField = buffer.f_fstypename
        let filesystemTypeCapacity = MemoryLayout.size(ofValue: filesystemTypeField)
        let filesystemType = withUnsafePointer(to: &filesystemTypeField) {
            $0.withMemoryRebound(to: CChar.self, capacity: filesystemTypeCapacity) {
                String(cString: $0)
            }
        }
        var mountPathField = buffer.f_mntonname
        let mountPathCapacity = MemoryLayout.size(ofValue: mountPathField)
        let mountPath = withUnsafePointer(to: &mountPathField) {
            $0.withMemoryRebound(to: CChar.self, capacity: mountPathCapacity) {
                String(cString: $0)
            }
        }
        return (filesystemType, mountPath, (buffer.f_flags & UInt32(MNT_RDONLY)) != 0)
    }
}
