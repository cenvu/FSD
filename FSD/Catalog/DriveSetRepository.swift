import Foundation

/// Local catalog organization only. No source observation, identity inference or
/// snapshot relationship. Membership is an explicit pair of opaque local IDs.
public final class DriveSetRepository {
    public static let maximumPageSize = 200
    public static let normalizationVersion = "fsd-drive-set-name-v1"
    private let database: CatalogDatabase
    private let identities: PhysicalDriveRepository
    public init(database: CatalogDatabase) {
        self.database = database; identities = PhysicalDriveRepository(database: database)
    }
    public static func normalize(_ name: String) -> String {
        PathIdentity.caseFold(name.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    private static func name(_ raw: String) throws -> (String, String) {
        guard raw.utf8.count <= 1024 else { throw DriveSetError.invalidName }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = normalize(trimmed)
        guard !trimmed.isEmpty, trimmed.utf8.count <= 256, !trimmed.contains("\0"),
              !normalized.isEmpty, normalized.utf8.count <= 1024 else { throw DriveSetError.invalidName }
        return (trimmed, normalized)
    }
    @discardableResult
    public func create(id: DriveSetID = DriveSetID(), name: String) throws -> DriveSet {
        let (display, normalized) = try Self.name(name)
        return try database.transaction {
            if let existing = try set(id: id) {
                guard existing.name == display, existing.normalizedName == normalized else { throw DriveSetError.operationMismatch }
                return existing
            }
            try checkDuplicate(normalized, excluding: id)
            try database.execute("INSERT INTO drive_sets(id,name,normalized_name,normalization_version,created_at,updated_at) VALUES (?,?,?,?,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)",
                bindings: [.text(id.rawValue.uuidString), .text(display), .text(normalized), .text(Self.normalizationVersion)])
            guard let created = try set(id: id) else { throw DriveSetError.corruptRecord }
            return created
        }
    }
    public func set(id: DriveSetID) throws -> DriveSet? {
        try database.query("SELECT * FROM drive_sets WHERE id=? LIMIT 1", bindings: [.text(id.rawValue.uuidString)]).first.map(Self.decode)
    }
    private func require(_ id: DriveSetID, _ revision: Int64) throws -> DriveSet {
        guard let record = try set(id: id) else { throw DriveSetError.notFound }
        guard revision > 0, revision == record.revision else { throw DriveSetError.staleRevision }
        return record
    }
    private func checkDuplicate(_ normalized: String, excluding id: DriveSetID) throws {
        if try database.scalar("SELECT 1 FROM drive_sets WHERE normalized_name=? AND id!=? LIMIT 1",
            bindings: [.text(normalized), .text(id.rawValue.uuidString)]) != nil { throw DriveSetError.duplicateName }
    }
    @discardableResult
    public func rename(id: DriveSetID, expectedRevision: Int64, name: String) throws -> DriveSet {
        let (display, normalized) = try Self.name(name)
        return try database.transaction {
            let prior = try require(id, expectedRevision)
            try checkDuplicate(normalized, excluding: id)
            if prior.name == display { return prior }
            try database.execute("UPDATE drive_sets SET name=?,normalized_name=?,revision=revision+1,updated_at=CURRENT_TIMESTAMP WHERE id=? AND revision=?",
                bindings: [.text(display), .text(normalized), .text(id.rawValue.uuidString), .integer(expectedRevision)])
            guard let updated = try set(id: id) else { throw DriveSetError.corruptRecord }
            return updated
        }
    }
    /// An absent set is already deleted. An existing set requires its current revision.
    public func delete(id: DriveSetID, expectedRevision: Int64) throws {
        try database.transaction {
            guard try set(id: id) != nil else { return }
            _ = try require(id, expectedRevision)
            try database.execute("DELETE FROM drive_sets WHERE id=?", bindings: [.text(id.rawValue.uuidString)])
        }
    }
    /// Repeating an already-current pair is a no-op after revision validation.
    /// A stale caller must refresh; a retry never overrides newer organization.
    @discardableResult
    public func setMembership(setID: DriveSetID, expectedRevision: Int64, driveID: PhysicalDriveID,
                              expectedDriveRevision: Int64, included: Bool) throws -> DriveSet {
        try database.transaction {
            let prior = try require(setID, expectedRevision)
            guard let drive = try identities.drive(id: driveID) else { throw DriveSetError.missingDrive }
            guard drive.revision == expectedDriveRevision else { throw DriveSetError.staleRevision }
            if included && drive.retired { throw DriveSetError.retiredDrive }
            let pair: [DatabaseValue] = [.text(setID.rawValue.uuidString), .text(driveID.rawValue.uuidString)]
            let exists = try database.scalar("SELECT 1 FROM drive_set_memberships WHERE set_id=? AND physical_drive_id=? LIMIT 1", bindings: pair) != nil
            guard exists != included else { return prior }
            if included {
                try database.execute("INSERT INTO drive_set_memberships(set_id,physical_drive_id,added_at,admission) VALUES (?,?,CURRENT_TIMESTAMP,'explicit_local_selection')", bindings: pair)
            } else {
                try database.execute("DELETE FROM drive_set_memberships WHERE set_id=? AND physical_drive_id=?", bindings: pair)
            }
            try database.execute("UPDATE drive_sets SET revision=revision+1,updated_at=CURRENT_TIMESTAMP WHERE id=?", bindings: [.text(setID.rawValue.uuidString)])
            guard let updated = try set(id: setID) else { throw DriveSetError.corruptRecord }
            return updated
        }
    }
    /// Keyset pages. Cursors describe ordering, not frozen history; refresh after mutations.
    public func list(after cursor: DriveSetCursor? = nil, limit: Int = 100) throws -> DriveSetPage {
        let size = max(1, min(Self.maximumPageSize, limit))
        let rows = try database.query("SELECT * FROM drive_sets WHERE (normalized_name,id) > (?,?) ORDER BY normalized_name,id LIMIT ?",
            bindings: [.text(cursor?.normalizedName ?? ""), .text(cursor?.id.rawValue.uuidString ?? ""), .integer(Int64(size + 1))])
        let records = try rows.prefix(size).map(Self.decode)
        let next = rows.count > size ? records.last.map { DriveSetCursor(normalizedName: $0.normalizedName, id: $0.id) } : nil
        return DriveSetPage(records: records, next: next)
    }
    /// Bounded ID page, including retired records so their membership stays visible.
    public func members(setID: DriveSetID, after: PhysicalDriveID? = nil, limit: Int = 100) throws -> IdentityPage<PhysicalDrive> {
        guard try set(id: setID) != nil else { throw DriveSetError.notFound }
        let size = max(1, min(Self.maximumPageSize, limit))
        let rows = try database.query("SELECT d.* FROM drive_set_memberships m JOIN physical_drives d ON d.id=m.physical_drive_id WHERE m.set_id=? AND m.physical_drive_id>? ORDER BY m.physical_drive_id LIMIT ?",
            bindings: [.text(setID.rawValue.uuidString), .text(after?.rawValue.uuidString ?? ""), .integer(Int64(size + 1))])
        return IdentityPage(records: try rows.prefix(size).map(PhysicalDriveRepository.makeDrive), isTruncated: rows.count > size)
    }
    private static func decode(_ row: DatabaseRow) throws -> DriveSet {
        guard let raw = row["id"]?.stringValue, let uuid = UUID(uuidString: raw), let name = row["name"]?.stringValue,
              let normalized = row["normalized_name"]?.stringValue, normalized == normalize(name),
              row["normalization_version"]?.stringValue == normalizationVersion,
              let revision = row["revision"]?.int64Value, revision > 0,
              let created = row["created_at"]?.stringValue, let updated = row["updated_at"]?.stringValue else { throw DriveSetError.corruptRecord }
        return DriveSet(id: DriveSetID(rawValue: uuid), name: name, normalizedName: normalized, revision: revision, createdAt: created, updatedAt: updated)
    }
}
