import Foundation

/// Catalog-only foundation. No source paths, providers, device APIs or snapshot
/// joins. Observations are supplied explicitly and never reused as match rules.
public final class PhysicalDriveRepository {
    public static let maximumPageSize = 200
    public static let maximumEvidencePerObservation = 32
    public static let approvedRealStrongProfileCount = 0
    private let database: CatalogDatabase
    public init(database: CatalogDatabase) { self.database = database }

    @discardableResult
    public func createDrive(id: PhysicalDriveID = PhysicalDriveID(), label: String? = nil,
                            provenance: String) throws -> PhysicalDrive {
        try Self.text(provenance, maximum: 1024)
        if let label { try Self.text(label, maximum: 256) }
        return try database.transaction {
            if let existing = try drive(id: id) {
                guard existing.label == label, existing.provenance == provenance, !existing.retired else {
                    throw PhysicalDriveIdentityError.operationMismatch
                }
                return existing
            }
            try database.execute("""
                INSERT INTO physical_drives(id,label,admission,provenance,created_at,updated_at)
                VALUES (?,?,'explicit_local',?,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)
                """, bindings: [.text(id.rawValue.uuidString), label.map(DatabaseValue.text) ?? .null, .text(provenance)])
            guard let result = try drive(id: id) else { throw PhysicalDriveIdentityError.corruptRecord }
            return result
        }
    }

    public func drive(id: PhysicalDriveID) throws -> PhysicalDrive? {
        try database.query("SELECT * FROM physical_drives WHERE id = ? LIMIT 1",
                           bindings: [.text(id.rawValue.uuidString)]).first.map(Self.makeDrive)
    }

    public func drives(after id: PhysicalDriveID? = nil, limit: Int = 100) throws -> IdentityPage<PhysicalDrive> {
        let size = Self.pageSize(limit)
        let rows = try database.query("SELECT * FROM physical_drives WHERE id > ? ORDER BY id LIMIT ?",
            bindings: [.text(id?.rawValue.uuidString ?? ""), .integer(Int64(size + 1))])
        return IdentityPage(records: try rows.prefix(size).map(Self.makeDrive), isTruncated: rows.count > size)
    }

    /// Tombstone only. Existing associations remain auditable and resolve Conflict.
    @discardableResult
    public func retireDrive(id: PhysicalDriveID, expectedRevision: Int64) throws -> PhysicalDrive {
        try database.transaction {
            let prior = try requireDrive(id, revision: expectedRevision)
            guard !prior.retired else { throw PhysicalDriveIdentityError.retired }
            try database.execute("""
                UPDATE physical_drives SET retired=1,revision=revision+1,updated_at=CURRENT_TIMESTAMP
                WHERE id=? AND revision=?
                """, bindings: [.text(id.rawValue.uuidString), .integer(expectedRevision)])
            guard let result = try drive(id: id) else { throw PhysicalDriveIdentityError.corruptRecord }
            return result
        }
    }

    /// A frozen local subject in one caller-supplied session/revision. Recording
    /// a new revision means a new observation ID and requires fresh confirmation.
    /// The observation and its complete bounded evidence set commit together.
    @discardableResult
    public func recordObservation(id: UUID = UUID(), sessionID: UUID, revision: Int64,
                                  scope: IdentityScope, state: IdentityObservationState = .unknown,
                                  provenance: String, observedAt: Date,
                                  evidence: [IdentityEvidenceInput] = []) throws -> IdentityObservation {
        guard revision > 0, evidence.count <= Self.maximumEvidencePerObservation,
              observedAt.timeIntervalSince1970.isFinite else { throw PhysicalDriveIdentityError.invalidInput }
        try Self.text(provenance, maximum: 1024)
        var canonical: [IdentityEvidenceInput] = []
        var properties = Set<String>()
        for fact in evidence {
            guard fact.kind.scope == scope,
                  properties.insert(fact.provider.rawValue + ":" + fact.property).inserted else {
                throw PhysicalDriveIdentityError.invalidInput
            }
            try Self.text(fact.property, maximum: 256)
            try Self.text(fact.provenance, maximum: 1024)
            var value = fact.value
            if let candidate = value {
                try Self.text(candidate, maximum: 1024)
                if fact.kind.isUUID {
                    guard let uuid = UUID(uuidString: candidate), candidate.count == 36 else { throw PhysicalDriveIdentityError.invalidInput }
                    value = uuid.uuidString
                }
            }
            guard (fact.validation == .unknown) == (value == nil) else { throw PhysicalDriveIdentityError.invalidInput }
            canonical.append(IdentityEvidenceInput(kind: fact.kind, provider: fact.provider, property: fact.property,
                value: value, validation: fact.validation, provenance: fact.provenance))
        }
        let time = ISO8601DateFormatter().string(from: observedAt)
        return try database.transaction {
            // Repeating an ID is an error, rather than silently accepting a changed observation.
            try database.execute("""
                INSERT INTO identity_observations(id,session_id,revision,scope,state,provenance,observed_at)
                VALUES (?,?,?,?,?,?,?)
                """, bindings: [.text(id.uuidString), .text(sessionID.uuidString), .integer(revision),
                    .text(scope.rawValue), .text(state.rawValue), .text(provenance), .text(time)])
            for fact in canonical {
                try database.execute("""
                    INSERT INTO identity_evidence(id,observation_id,observation_revision,scope,kind,provider,property,
                        dependency_group,value,validation,provenance,observed_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
                    """, bindings: [.text(UUID().uuidString), .text(id.uuidString), .integer(revision), .text(scope.rawValue),
                        .text(fact.kind.rawValue), .text(fact.provider.rawValue), .text(fact.property),
                        .text(fact.kind.dependencyGroup), fact.value.map(DatabaseValue.text) ?? .null,
                        .text(fact.validation.rawValue), .text(fact.provenance), .text(time)])
            }
            guard let result = try observation(id: id) else { throw PhysicalDriveIdentityError.corruptRecord }
            return result
        }
    }

    public func observation(id: UUID) throws -> IdentityObservation? {
        try database.query("SELECT * FROM identity_observations WHERE id=? LIMIT 1", bindings: [.text(id.uuidString)])
            .first.map { row in
                guard let session = UUID(uuidString: try Self.string(row,"session_id")),
                      let scope = IdentityScope(rawValue: try Self.string(row,"scope")),
                      let state = IdentityObservationState(rawValue: try Self.string(row,"state")) else {
                    throw PhysicalDriveIdentityError.corruptRecord
                }
                return IdentityObservation(id: id, sessionID: session, revision: try Self.integer(row,"revision"),
                    scope: scope, state: state, provenance: try Self.string(row,"provenance"), observedAt: try Self.string(row,"observed_at"))
            }
    }

    public func evidence(observationID: UUID) throws -> [IdentityEvidence] {
        try database.query("SELECT * FROM identity_evidence WHERE observation_id=? ORDER BY id LIMIT ?",
            bindings: [.text(observationID.uuidString), .integer(Int64(Self.maximumEvidencePerObservation + 1))]).map { row in
                guard let id = UUID(uuidString: try Self.string(row,"id")),
                      let scope = IdentityScope(rawValue: try Self.string(row,"scope")),
                      let kind = IdentityEvidenceKind(rawValue: try Self.string(row,"kind")),
                      let provider = IdentityEvidenceProvider(rawValue: try Self.string(row,"provider")),
                      let validation = IdentityEvidenceValidation(rawValue: try Self.string(row,"validation")) else {
                    throw PhysicalDriveIdentityError.corruptRecord
                }
                return IdentityEvidence(id: id, observationID: observationID, observationRevision: try Self.integer(row,"observation_revision"),
                    scope: scope, fact: IdentityEvidenceInput(kind: kind, provider: provider, property: try Self.string(row,"property"),
                        value: row["value"]?.stringValue, validation: validation, provenance: try Self.string(row,"provenance")),
                    observedAt: try Self.string(row,"observed_at"))
            }
    }

    /// Explicit associate/correct/revoke; expected assertion revision is zero
    /// before the first event. Retry uses the SAME operation ID and exact intent.
    @discardableResult
    public func setManualAssociation(operationID: UUID, observationID: UUID, expectedObservationRevision: Int64,
                                     expectedAssociationRevision: Int64, target: PhysicalDriveID?,
                                     expectedTargetRevision: Int64?, action: ManualAssociationAction,
                                     actor: String, reason: String) throws -> ManualDriveAssociation {
        try Self.text(actor, maximum: 256); try Self.text(reason, maximum: 1024)
        guard expectedAssociationRevision >= 0, expectedAssociationRevision < Int64.max,
              expectedObservationRevision > 0,
              (action == .revoke ? target == nil && expectedTargetRevision == nil : target != nil && expectedTargetRevision != nil)
        else { throw PhysicalDriveIdentityError.invalidInput }
        return try database.transaction {
            if let previous = try event(id: operationID) {
                guard previous.observationID == observationID, previous.observationRevision == expectedObservationRevision,
                      previous.revision == expectedAssociationRevision + 1, previous.target == target,
                      previous.targetRevision == expectedTargetRevision, previous.action == action,
                      previous.actor == actor, previous.reason == reason else { throw PhysicalDriveIdentityError.operationMismatch }
                return previous
            }
            guard let observed = try observation(id: observationID) else { throw PhysicalDriveIdentityError.notFound }
            guard observed.revision == expectedObservationRevision else { throw PhysicalDriveIdentityError.staleRevision }
            let prior = try latestAssociation(observationID: observationID)
            guard (prior?.revision ?? 0) == expectedAssociationRevision else { throw PhysicalDriveIdentityError.staleRevision }
            guard action == .associate ? prior == nil : prior != nil else { throw PhysicalDriveIdentityError.conflict }
            if let target, let expectedTargetRevision {
                _ = try requireDrive(target, revision: expectedTargetRevision)
                guard [.volume,.partition].contains(observed.scope), try !hasConflict(observed) else { throw PhysicalDriveIdentityError.conflict }
            }
            try database.execute("""
                INSERT INTO manual_drive_associations(id,observation_id,observation_revision,revision,previous_event_id,
                    target_drive_id,target_revision,action,actor,reason,created_at) VALUES (?,?,?,?,?,?,?,?,?,?,CURRENT_TIMESTAMP)
                """, bindings: [.text(operationID.uuidString), .text(observationID.uuidString), .integer(expectedObservationRevision),
                    .integer(expectedAssociationRevision + 1), prior.map { .text($0.operationID.uuidString) } ?? .null,
                    target.map { .text($0.rawValue.uuidString) } ?? .null, expectedTargetRevision.map(DatabaseValue.integer) ?? .null,
                    .text(action.rawValue), .text(actor), .text(reason)])
            guard let result = try event(id: operationID) else { throw PhysicalDriveIdentityError.corruptRecord }
            return result
        }
    }

    public func latestAssociation(observationID: UUID) throws -> ManualDriveAssociation? {
        try database.query("SELECT * FROM manual_drive_associations WHERE observation_id=? ORDER BY revision DESC LIMIT 1",
            bindings: [.text(observationID.uuidString)]).first.map(Self.makeEvent)
    }
    public func associationHistory(observationID: UUID, afterRevision: Int64 = 0, limit: Int = 100) throws -> IdentityPage<ManualDriveAssociation> {
        let size = Self.pageSize(limit)
        let rows = try database.query("SELECT * FROM manual_drive_associations WHERE observation_id=? AND revision>? ORDER BY revision LIMIT ?",
            bindings: [.text(observationID.uuidString), .integer(afterRevision), .integer(Int64(size + 1))])
        return IdentityPage(records: try rows.prefix(size).map(Self.makeEvent), isTruncated: rows.count > size)
    }

    /// There is intentionally no automatic candidate matcher. Ambiguity/conflict
    /// supplied with an observation persists, and alias disagreements fail closed.
    public func resolution(observationID: UUID) throws -> PhysicalDriveResolution {
        guard let observed = try observation(id: observationID) else { throw PhysicalDriveIdentityError.notFound }
        if try hasConflict(observed) { return .conflict }
        if let current = try latestAssociation(observationID: observationID), let target = current.target {
            guard let drive = try drive(id: target), !drive.retired else { return .conflict }
            return .manualAssociation(target)
        }
        return observed.state == .ambiguous ? .ambiguous : .unknown
    }

    private func hasConflict(_ observation: IdentityObservation) throws -> Bool {
        if observation.state == .conflict { return true }
        let facts = try evidence(observationID: observation.id)
        guard facts.count <= Self.maximumEvidencePerObservation else { return true }
        if facts.contains(where: { $0.fact.validation == .conflict }) { return true }
        let groups = Dictionary(grouping: facts, by: \.dependencyGroup)
        return groups.values.contains { Set($0.compactMap { $0.fact.value }).count > 1 }
    }
    private func requireDrive(_ id: PhysicalDriveID, revision: Int64) throws -> PhysicalDrive {
        guard let record = try drive(id: id) else { throw PhysicalDriveIdentityError.notFound }
        guard record.revision == revision else { throw PhysicalDriveIdentityError.staleRevision }
        guard !record.retired else { throw PhysicalDriveIdentityError.retired }
        return record
    }
    private func event(id: UUID) throws -> ManualDriveAssociation? {
        try database.query("SELECT * FROM manual_drive_associations WHERE id=? LIMIT 1", bindings: [.text(id.uuidString)]).first.map(Self.makeEvent)
    }
    private static func pageSize(_ value: Int) -> Int { min(maximumPageSize, max(1,value)) }
    private static func text(_ value: String, maximum: Int) throws {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              value.utf8.count <= maximum, !value.utf8.contains(0) else { throw PhysicalDriveIdentityError.invalidInput }
    }
    private static func string(_ row: DatabaseRow, _ key: String) throws -> String {
        guard let value = row[key]?.stringValue else { throw PhysicalDriveIdentityError.corruptRecord }; return value
    }
    private static func integer(_ row: DatabaseRow, _ key: String) throws -> Int64 {
        guard let value = row[key]?.int64Value else { throw PhysicalDriveIdentityError.corruptRecord }; return value
    }
    static func makeDrive(_ row: DatabaseRow) throws -> PhysicalDrive {
        guard let id = UUID(uuidString: try string(row,"id")) else { throw PhysicalDriveIdentityError.corruptRecord }
        return PhysicalDrive(id: PhysicalDriveID(rawValue: id), label: row["label"]?.stringValue,
            provenance: try string(row,"provenance"), revision: try integer(row,"revision"), retired: try integer(row,"retired") == 1,
            createdAt: try string(row,"created_at"), updatedAt: try string(row,"updated_at"))
    }
    private static func makeEvent(_ row: DatabaseRow) throws -> ManualDriveAssociation {
        guard let id = UUID(uuidString: try string(row,"id")), let observed = UUID(uuidString: try string(row,"observation_id")),
              let action = ManualAssociationAction(rawValue: try string(row,"action")) else { throw PhysicalDriveIdentityError.corruptRecord }
        let target = row["target_drive_id"]?.stringValue.flatMap(UUID.init(uuidString:)).map { PhysicalDriveID(rawValue: $0) }
        return ManualDriveAssociation(operationID: id, observationID: observed, observationRevision: try integer(row,"observation_revision"),
            revision: try integer(row,"revision"), previousEventID: row["previous_event_id"]?.stringValue.flatMap(UUID.init(uuidString:)),
            target: target, targetRevision: row["target_revision"]?.int64Value, action: action,
            actor: try string(row,"actor"), reason: try string(row,"reason"), createdAt: try string(row,"created_at"))
    }
}
