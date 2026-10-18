import Foundation

public enum SourceObservationCompleteness: String, Sendable { case complete, partial }

/// A generated, immutable single-subject input, not a live mount notification.
/// A new observation revision has a new local ID. No path/value is dereferenced.
public struct SourceObservationEnvelope: Equatable, Sendable {
    public static let maximumEvidence = 32
    public let observation: IdentityObservation
    public let evidence: [IdentityEvidenceInput]
    public let completeness: SourceObservationCompleteness

    public init(observationID: UUID, sessionID: UUID, revision: Int64, scope: IdentityScope,
                state: IdentityObservationState = .unknown, provenance: String = "", observedAt: Date,
                evidence: [IdentityEvidenceInput] = [], completeness: SourceObservationCompleteness = .partial) throws {
        guard observedAt.timeIntervalSince1970.isFinite else { throw PhysicalDriveIdentityError.invalidInput }
        try self.init(observation: IdentityObservation(id: observationID, sessionID: sessionID, revision: revision,
            scope: scope, state: state, provenance: provenance, observedAt: ISO8601DateFormatter().string(from: observedAt)),
            evidence: evidence, completeness: completeness)
    }

    public init(observation: IdentityObservation, evidence: [IdentityEvidenceInput] = [],
                completeness: SourceObservationCompleteness = .partial) throws {
        guard observation.revision > 0, evidence.count <= Self.maximumEvidence else {
            throw PhysicalDriveIdentityError.invalidInput
        }
        try Self.text(observation.provenance, maximum: 1024, allowMissing: true)
        try Self.text(observation.observedAt, maximum: 256)
        guard ISO8601DateFormatter().date(from: observation.observedAt) != nil else {
            throw PhysicalDriveIdentityError.invalidInput
        }
        var canonical: [IdentityEvidenceInput] = []
        for fact in evidence {
            guard fact.kind.scope == observation.scope,
                  (fact.validation == .unknown) == (fact.value == nil) else {
                throw PhysicalDriveIdentityError.invalidInput
            }
            try Self.text(fact.property, maximum: 256)
            try Self.text(fact.provenance, maximum: 1024, allowMissing: true)
            var value = fact.value
            if let candidate = value {
                try Self.text(candidate, maximum: 1024)
                if fact.kind.isUUID {
                    guard candidate.count == 36, let uuid = UUID(uuidString: candidate) else {
                        throw PhysicalDriveIdentityError.invalidInput
                    }
                    value = uuid.uuidString
                }
            }
            let normalized = IdentityEvidenceInput(kind: fact.kind, provider: fact.provider,
                property: fact.property, value: value, validation: fact.validation, provenance: fact.provenance)
            // Exact duplicate deliveries carry no additional evidence. Contradictory
            // duplicates remain present for the conflict check, independent of order.
            if !canonical.contains(normalized) { canonical.append(normalized) }
        }
        self.observation = observation
        self.evidence = canonical.sorted { Self.key($0).lexicographicallyPrecedes(Self.key($1)) }
        self.completeness = completeness
    }

    /// Dependency groups are kind-scoped, host-defined lineages, never caller
    /// supplied independence claims. Different providers do not create new proof.
    public var dependencyGroups: [String] { Set(evidence.map { $0.kind.dependencyGroup }).sorted() }
    public var hasUnknownProvenance: Bool {
        observation.provenance.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        evidence.contains { $0.provenance.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    private static func key(_ fact: IdentityEvidenceInput) -> [String] {
        [fact.kind.rawValue, fact.provider.rawValue, fact.property, fact.value ?? "",
         fact.validation.rawValue, fact.provenance]
    }
    private static func text(_ value: String, maximum: Int, allowMissing: Bool = false) throws {
        guard value.utf8.count <= maximum, !value.utf8.contains(0),
              allowMissing || !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PhysicalDriveIdentityError.invalidInput
        }
    }
}

public struct SourceObservationResolution: Equatable, Sendable {
    public let outcome: PhysicalDriveResolution
    /// Sorted, deduplicated hypotheses supplied explicitly by the caller. The
    /// resolver does not discover candidates from names, UUIDs, paths or serials.
    public let candidateIDs: [PhysicalDriveID]
}

/// Stateless synthetic-input policy. No dependencies, I/O, callbacks or writes.
/// Precedence: explicit conflict/alias disagreement; inconsistent candidate or
/// stale manual references; incomplete candidate coverage; current manual choice;
/// original ambiguity/multiple hypotheses; Unknown. Missing facts/provenance do
/// not contradict an otherwise current deliberate manual decision. All candidates
/// are provisional: zero approved profiles means no UniqueStrongMatch producer.
public enum SourceObservationResolver {
    public static let maximumCandidates = 200
    public static var approvedRealStrongProfileCount: Int { PhysicalDriveRepository.approvedRealStrongProfileCount }

    public static func resolve(_ envelope: SourceObservationEnvelope, candidates: [PhysicalDrive] = [],
                               association: ManualDriveAssociation? = nil, manualTarget: PhysicalDrive? = nil,
                               expectedAssociationRevision: Int64 = 0,
                               candidateCoverageComplete: Bool = true) throws -> SourceObservationResolution {
        guard candidates.count <= maximumCandidates, expectedAssociationRevision >= 0 else {
            throw PhysicalDriveIdentityError.invalidInput
        }
        let ids = Set(candidates.map(\.id)).sorted { $0.rawValue.uuidString < $1.rawValue.uuidString }
        func result(_ outcome: PhysicalDriveResolution) -> SourceObservationResolution {
            SourceObservationResolution(outcome: outcome, candidateIDs: ids)
        }
        if envelope.observation.state == .conflict || envelope.evidence.contains(where: { $0.validation == .conflict }) {
            return result(.conflict)
        }
        let groups = Dictionary(grouping: envelope.evidence, by: { $0.kind.dependencyGroup })
        if groups.values.contains(where: { Set($0.compactMap(\.value)).count > 1 }) { return result(.conflict) }
        let records = Dictionary(grouping: candidates, by: \.id)
        if records.values.contains(where: { rows in
            rows.contains { $0 != rows[0] || $0.retired || $0.revision <= 0 }
        }) { return result(.conflict) }
        guard (association?.revision ?? 0) == expectedAssociationRevision else { return result(.conflict) }
        if let association {
            guard association.revision > 0, association.observationID == envelope.observation.id,
                  association.observationRevision == envelope.observation.revision,
                  (association.revision == 1 ? association.action == .associate && association.previousEventID == nil :
                    association.action != .associate && association.previousEventID != nil),
                  !association.actor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !association.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return result(.conflict) }
            if association.action == .revoke {
                guard association.target == nil, association.targetRevision == nil, manualTarget == nil else { return result(.conflict) }
            } else {
                guard [.volume, .partition].contains(envelope.observation.scope),
                      let target = manualTarget, association.target == target.id,
                      association.targetRevision == target.revision, target.revision > 0, !target.retired,
                      records[target.id]?.allSatisfy({ $0 == target }) ?? true else { return result(.conflict) }
            }
        } else if manualTarget != nil { return result(.conflict) }
        // Unknown candidate coverage cannot be hidden by a manual/recency choice.
        guard candidateCoverageComplete else { return result(.conflict) }
        if let association, association.action != .revoke, let target = association.target {
            return result(.manualAssociation(target))
        }
        if envelope.observation.state == .ambiguous || ids.count > 1 { return result(.ambiguous) }
        return result(.unknown)
    }
}
