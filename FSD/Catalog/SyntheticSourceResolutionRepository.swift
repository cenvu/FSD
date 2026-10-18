import Foundation

/// Read-only integration seam for generated envelopes and explicit candidate IDs.
/// Uses the existing serialized transaction for a consistent catalog view, with
/// bounded indexed reads only. It does not record observations or associations.
/// The returned value is a point-in-time result, never a capture admission token.
public final class SyntheticSourceResolutionRepository {
    private let database: CatalogDatabase
    private let identities: PhysicalDriveRepository
    public init(database: CatalogDatabase) {
        self.database = database
        self.identities = PhysicalDriveRepository(database: database)
    }

    public func resolve(_ envelope: SourceObservationEnvelope, expectedAssociationRevision: Int64,
                        candidateIDs: [PhysicalDriveID] = [],
                        candidateCoverageComplete: Bool = true) throws -> SourceObservationResolution {
        guard candidateIDs.count <= SourceObservationResolver.maximumCandidates,
              expectedAssociationRevision >= 0 else { throw PhysicalDriveIdentityError.invalidInput }
        let ids = Set(candidateIDs).sorted { $0.rawValue.uuidString < $1.rawValue.uuidString }
        func conflict() -> SourceObservationResolution { SourceObservationResolution(outcome: .conflict, candidateIDs: ids) }
        return try database.transaction {
            guard let stored = try identities.observation(id: envelope.observation.id),
                  stored == envelope.observation else { return conflict() }
            let evidence = try identities.evidence(observationID: stored.id)
            guard evidence.allSatisfy({ $0.observationID == stored.id && $0.observationRevision == stored.revision && $0.scope == stored.scope }),
                  try SourceObservationEnvelope(observation: stored, evidence: evidence.map(\.fact),
                    completeness: envelope.completeness) == envelope else { return conflict() }
            var candidates: [PhysicalDrive] = []
            for id in ids {
                guard let drive = try identities.drive(id: id) else { return conflict() }
                candidates.append(drive)
            }
            let association = try identities.latestAssociation(observationID: stored.id)
            let target = try association?.target.flatMap { try identities.drive(id: $0) }
            return try SourceObservationResolver.resolve(envelope, candidates: candidates,
                association: association, manualTarget: target, expectedAssociationRevision: expectedAssociationRevision,
                candidateCoverageComplete: candidateCoverageComplete)
        }
    }
}
