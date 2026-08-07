import Foundation

public struct JSONSnapshotExportSummary: Equatable, Sendable {
    public let snapshotID: SnapshotID
    public let entryCount: Int64
    public let issueCount: Int64
    public let byteCount: Int64
}

public enum JSONSnapshotExportError: Error, LocalizedError, Equatable {
    case snapshotNotFound(SnapshotID)
    case cannotWrite(URL, String)

    public var errorDescription: String? {
        switch self {
        case let .snapshotNotFound(id): return "Snapshot \(id) was not found."
        case let .cannotWrite(url, message): return "Cannot write the export to \(url.path): \(message)"
        }
    }
}

/// Deterministic, metadata-only JSON export of one stored snapshot.
///
/// Offline by construction: every value comes from the catalog, so an export
/// runs with the source ejected and never re-reads it. Payload bytes, content
/// hashes and classification results are not merely omitted — there is no query
/// here that could produce them, and `entry_classifications` is never joined.
///
/// Output is streamed in bounded pages through a sink and ordered by
/// `relative_path`, which is unique within a snapshot, so exporting the same
/// snapshot twice produces byte-identical output.
///
/// Reading the snapshot never writes to it: the export runs entirely on SELECT
/// statements outside any transaction that could mutate catalog state.
public final class JSONSnapshotExporter {
    public static let formatIdentifier = "fsd.snapshot.metadata"
    public static let formatVersion = 1
    public static let contentDisclaimer =
        "Metadata only. Content Not Verified. This export describes recorded file metadata; "
        + "it makes no claim about file contents and is not a checksum, a verification, or proof of a bit-identical copy."

    public let pageSize: Int
    private let database: CatalogDatabase

    public init(database: CatalogDatabase, pageSize: Int = 1000) {
        self.database = database
        self.pageSize = max(1, pageSize)
    }

    @discardableResult
    public func export(snapshotID: SnapshotID, to url: URL) throws -> JSONSnapshotExportSummary {
        // Write-only, to a destination the caller chose. Never a scanned source.
        guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
            throw JSONSnapshotExportError.cannotWrite(url, "the destination could not be created")
        }
        let handle: FileHandle
        do {
            handle = try FileHandle(forWritingTo: url)
        } catch {
            throw JSONSnapshotExportError.cannotWrite(url, error.localizedDescription)
        }
        defer { try? handle.close() }
        do {
            return try write(snapshotID: snapshotID) { chunk in
                guard let data = chunk.data(using: .utf8) else { return }
                try handle.write(contentsOf: data)
            }
        } catch let error as JSONSnapshotExportError {
            throw error
        } catch let error as CatalogDatabaseError {
            throw error
        } catch {
            throw JSONSnapshotExportError.cannotWrite(url, error.localizedDescription)
        }
    }

    /// Streams the document to `sink` in bounded pieces. Nothing larger than one
    /// page of entries is ever held in memory.
    @discardableResult
    public func write(snapshotID: SnapshotID, sink: (String) throws -> Void) throws -> JSONSnapshotExportSummary {
        let history = SnapshotHistoryRepository(database: database)
        guard let summary = try history.summary(id: snapshotID) else {
            throw JSONSnapshotExportError.snapshotNotFound(snapshotID)
        }

        var byteCount: Int64 = 0
        func emit(_ chunk: String) throws {
            byteCount += Int64(chunk.utf8.count)
            try sink(chunk)
        }

        try emit("{\n")
        try emit("  \"format\": \(Self.json(Self.formatIdentifier)),\n")
        try emit("  \"formatVersion\": \(Self.formatVersion),\n")
        try emit("  \"catalogSchemaVersion\": \(CatalogMigrations.currentVersion),\n")
        try emit("  \"contentVerified\": false,\n")
        try emit("  \"disclaimer\": \(Self.json(Self.contentDisclaimer)),\n")
        try emit("  \"snapshot\": {\n")
        try emit(Self.snapshotBody(summary))
        try emit("  },\n")

        let issueCount = try writeIssues(snapshotID: snapshotID, emit: emit)
        let entryCount = try writeEntries(snapshotID: snapshotID, emit: emit)

        try emit("}\n")
        return JSONSnapshotExportSummary(
            snapshotID: snapshotID,
            entryCount: entryCount,
            issueCount: issueCount,
            byteCount: byteCount
        )
    }

    private func writeIssues(snapshotID: SnapshotID, emit: (String) throws -> Void) throws -> Int64 {
        try emit("  \"scanIssues\": [\n")
        var count: Int64 = 0
        var lastID: Int64 = 0
        while true {
            let rows = try database.query(
                """
                SELECT id, relative_path, severity, source, message, was_skipped
                FROM scan_issues WHERE snapshot_id = ? AND id > ? ORDER BY id LIMIT ?
                """,
                bindings: [.integer(snapshotID.rawValue), .integer(lastID), .integer(Int64(pageSize))]
            )
            if rows.isEmpty { break }
            for row in rows {
                lastID = row["id"]?.int64Value ?? lastID
                if count > 0 { try emit(",\n") }
                var fields: [(String, String)] = []
                fields.append(("relativePath", Self.json(row["relative_path"]?.stringValue ?? "")))
                fields.append(("severity", Self.json(row["severity"]?.stringValue ?? "")))
                fields.append(("source", Self.json(row["source"]?.stringValue ?? "")))
                fields.append(("message", Self.json(row["message"]?.stringValue ?? "")))
                fields.append(("wasSkipped", (row["was_skipped"]?.int64Value ?? 0) == 1 ? "true" : "false"))
                try emit("    { " + fields.map { "\(Self.json($0.0)): \($0.1)" }.joined(separator: ", ") + " }")
                count += 1
            }
            if rows.count < pageSize { break }
        }
        try emit(count > 0 ? "\n  ],\n" : "  ],\n")
        return count
    }

    private func writeEntries(snapshotID: SnapshotID, emit: (String) throws -> Void) throws -> Int64 {
        try emit("  \"entries\": [\n")
        var count: Int64 = 0
        var lastPath: String?
        while true {
            let bindings: [DatabaseValue] = lastPath
                .map { [.integer(snapshotID.rawValue), .text($0), .integer(Int64(pageSize))] }
                ?? [.integer(snapshotID.rawValue), .integer(Int64(pageSize))]
            let predicate = lastPath == nil ? "" : "AND relative_path > ? "
            let rows = try database.query(
                """
                SELECT relative_path, name, file_extension, item_type, logical_size_bytes,
                       allocated_size_bytes, created_at_source, modified_at_source,
                       content_type_identifier, symlink_target, is_hidden, is_package, is_inaccessible
                FROM entries WHERE snapshot_id = ? \(predicate)ORDER BY relative_path LIMIT ?
                """,
                bindings: bindings
            )
            if rows.isEmpty { break }
            for row in rows {
                lastPath = row["relative_path"]?.stringValue ?? lastPath
                if count > 0 { try emit(",\n") }
                try emit("    " + Self.entryObject(row))
                count += 1
            }
            if rows.count < pageSize { break }
        }
        try emit(count > 0 ? "\n  ]\n" : "  ]\n")
        return count
    }

    private static func entryObject(_ row: DatabaseRow) -> String {
        var fields: [(String, String)] = [
            ("relativePath", json(row["relative_path"]?.stringValue ?? "")),
            ("name", json(row["name"]?.stringValue ?? "")),
            ("itemType", json(row["item_type"]?.stringValue ?? ""))
        ]
        fields.append(("fileExtension", jsonOrNull(row["file_extension"]?.stringValue)))
        fields.append(("logicalSizeBytes", row["logical_size_bytes"]?.int64Value.map(String.init) ?? "null"))
        fields.append(("allocatedSizeBytes", row["allocated_size_bytes"]?.int64Value.map(String.init) ?? "null"))
        fields.append(("createdAtSource", jsonOrNull(row["created_at_source"]?.stringValue)))
        fields.append(("modifiedAtSource", jsonOrNull(row["modified_at_source"]?.stringValue)))
        fields.append(("contentTypeIdentifier", jsonOrNull(row["content_type_identifier"]?.stringValue)))
        fields.append(("symlinkTarget", jsonOrNull(row["symlink_target"]?.stringValue)))
        fields.append(("isHidden", (row["is_hidden"]?.int64Value ?? 0) == 1 ? "true" : "false"))
        fields.append(("isPackage", (row["is_package"]?.int64Value ?? 0) == 1 ? "true" : "false"))
        fields.append(("isInaccessible", (row["is_inaccessible"]?.int64Value ?? 0) == 1 ? "true" : "false"))
        return "{ " + fields.map { "\(json($0.0)): \($0.1)" }.joined(separator: ", ") + " }"
    }

    private static func snapshotBody(_ summary: SnapshotSummary) -> String {
        var lines: [String] = []
        lines.append("    \"id\": \(summary.id.rawValue)")
        lines.append("    \"sessionNumber\": \(summary.sessionNumber)")
        lines.append("    \"displayName\": \(json(summary.displayName))")
        lines.append("    \"scanRootName\": \(json(summary.scanRootName))")
        lines.append("    \"status\": \(json(summary.status.rawValue))")
        lines.append("    \"isPartialCapture\": \(summary.isPartialCapture ? "true" : "false")")
        lines.append("    \"startedAt\": \(json(summary.startedAt))")
        lines.append("    \"completedAt\": \(jsonOrNull(summary.completedAt))")
        lines.append("    \"totalFiles\": \(summary.totalFiles)")
        lines.append("    \"totalFolders\": \(summary.totalFolders)")
        lines.append("    \"totalLogicalBytes\": \(summary.totalLogicalBytes)")
        lines.append("    \"totalAllocatedBytes\": \(summary.totalAllocatedBytes)")
        lines.append("    \"inaccessibleItems\": \(summary.inaccessibleItems)")
        lines.append("    \"warningCount\": \(summary.warningCount)")
        lines.append("    \"scannerVersion\": \(json(summary.scannerVersion))")
        lines.append("    \"filesystemProvider\": \(json(summary.filesystemProvider))")
        lines.append("    \"providerVersion\": \(jsonOrNull(summary.providerVersion))")
        lines.append("    \"sourceAccessMode\": \(json(summary.sourceAccessMode))")
        lines.append("    \"normalizationVersion\": \(json(summary.normalizationVersion.rawValue))")
        lines.append("    \"capturedSchemaVersion\": \(summary.schemaVersion)")
        // Capture-time source facts (ADR-023). Nothing here is read from the
        // mutable `volumes` registry, so an export of an old snapshot is not
        // rewritten by a later capture of the same volume.
        lines.append("    \"sourceAtCapture\": { "
            + "\"volumeDisplayName\": \(jsonOrNull(summary.capture.volumeDisplayName)), "
            + "\"volumeIdentifier\": \(jsonOrNull(summary.capture.volumeIdentifier)), "
            + "\"volumeTotalCapacityBytes\": \(summary.capture.volumeTotalCapacityBytes.map(String.init) ?? "null"), "
            + "\"mountPath\": \(jsonOrNull(summary.capture.mountPath)), "
            + "\"filesystemVariant\": \(jsonOrNull(summary.capture.filesystemVariant)), "
            + "\"caseSensitivity\": \(json(summary.capture.caseSensitivity.rawValue)), "
            + "\"isFullyRecorded\": \(summary.capture.isFullyRecorded ? "true" : "false")"
            + " }")
        return lines.joined(separator: ",\n") + "\n"
    }

    private static func jsonOrNull(_ value: String?) -> String {
        value.map(json) ?? "null"
    }

    /// Minimal RFC 8259 string escaping. Written out rather than delegated to
    /// `JSONSerialization` because the export must be byte-deterministic, and
    /// `JSONSerialization` neither preserves key order nor streams.
    static func json(_ value: String) -> String {
        var output = "\""
        for scalar in value.unicodeScalars {
            switch scalar {
            case "\"": output += "\\\""
            case "\\": output += "\\\\"
            case "\n": output += "\\n"
            case "\r": output += "\\r"
            case "\t": output += "\\t"
            default:
                if scalar.value < 0x20 {
                    output += String(format: "\\u%04x", scalar.value)
                } else {
                    output.unicodeScalars.append(scalar)
                }
            }
        }
        return output + "\""
    }
}
