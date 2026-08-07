import Foundation

guard CommandLine.arguments.count > 1 else {
    print("Usage: spike <mount_path>")
    exit(1)
}

let mountPath = CommandLine.arguments[1]
let mountURL = URL(fileURLWithPath: mountPath)

let resourceKeys: [URLResourceKey] = [
    .nameKey,
    .isDirectoryKey,
    .isRegularFileKey,
    .isSymbolicLinkKey,
    .isPackageKey,
    .fileSizeKey,
    .fileAllocatedSizeKey,
    .creationDateKey,
    .contentModificationDateKey,
    .isHiddenKey,
    .typeIdentifierKey
]

do {
    let volKeys: [URLResourceKey] = [
        .volumeIdentifierKey,
        .volumeLocalizedFormatDescriptionKey,
        .volumeSupportsCaseSensitiveNamesKey,
        .volumeIsReadOnlyKey
    ]
    let volMeta = try mountURL.resourceValues(forKeys: Set(volKeys))
    print("--- VOLUME METADATA ---")
    print("Identifier: \(String(describing: volMeta.volumeIdentifier))")
    print("Format: \(String(describing: volMeta.volumeLocalizedFormatDescription))")
    print("Case Sensitive: \(String(describing: volMeta.volumeSupportsCaseSensitiveNames))")
    print("Read Only: \(String(describing: volMeta.volumeIsReadOnly))")
    print("-----------------------")
} catch {
    print("Volume metadata error: \(error)")
}

let errorHandler: (URL, Error) -> Bool = { url, error in
    print("ERROR enumerating \(url.path): \(error)")
    return true
}

guard let enumerator = FileManager.default.enumerator(
    at: mountURL,
    includingPropertiesForKeys: resourceKeys,
    options: [], 
    errorHandler: errorHandler
) else {
    print("Failed to create enumerator")
    exit(1)
}

print("--- ENUMERATION ---")
var count = 0
for case let fileURL as URL in enumerator {
    count += 1
    do {
        let values = try fileURL.resourceValues(forKeys: Set(resourceKeys))
        let relativePath = fileURL.path.replacingOccurrences(of: mountPath, with: "").trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        let pathString = (relativePath.isEmpty) ? fileURL.lastPathComponent : relativePath
        
        // Convert name to hex string
        let nameStr = values.name ?? ""
        let hexStr = nameStr.utf8.map { String(format: "%02x", $0) }.joined(separator: " ")
        
        print("Path: \(pathString)")
        print("  Name: \(nameStr)")
        print("  Name Hex: \(hexStr)")
        print("  isDir: \(values.isDirectory ?? false), isFile: \(values.isRegularFile ?? false), isSymlink: \(values.isSymbolicLink ?? false), isPackage: \(values.isPackage ?? false)")
        print("  Logical Size: \(values.fileSize ?? -1)")
        print("  Allocated Size: \(values.fileAllocatedSize ?? -1)")
        print("  Creation: \(String(describing: values.creationDate))")
        print("  Modification: \(String(describing: values.contentModificationDate))")
        print("  Hidden: \(values.isHidden ?? false)")
        print("  ContentType: \(String(describing: values.typeIdentifier))")
    } catch {
        print("Error getting resource values for \(fileURL.path): \(error)")
    }
}
print("Total entries: \(count)")
