import XCTest
@testable import FSD

/// SYNTHETIC ONLY. No empirical physical-device or real observer proof.
final class SourceObservationResolverTests: XCTestCase {
    private func uuid(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }
    private func drive(_ n: Int = 1, revision: Int64 = 1, retired: Bool = false) -> PhysicalDrive {
        PhysicalDrive(id: PhysicalDriveID(rawValue: uuid(n)), label: "same", provenance: "generated local record",
            revision: revision, retired: retired, createdAt: "then", updatedAt: "then")
    }
    private func observation(_ scope: IdentityScope = .volume, state: IdentityObservationState = .unknown,
                             revision: Int64 = 1, provenance: String = "synthetic") -> IdentityObservation {
        IdentityObservation(id: uuid(100), sessionID: uuid(200), revision: revision, scope: scope,
            state: state, provenance: provenance, observedAt: "2026-10-18T00:00:00Z")
    }
    private func fact(_ kind: IdentityEvidenceKind = .filesystemUUID, _ value: String? = nil,
                      provider: IdentityEvidenceProvider = .synthetic, property: String = "generated",
                      validation: IdentityEvidenceValidation = .unverified, provenance: String = "synthetic") -> IdentityEvidenceInput {
        IdentityEvidenceInput(kind: kind, provider: provider, property: property, value: value,
            validation: validation, provenance: provenance)
    }
    private func envelope(_ scope: IdentityScope = .volume, state: IdentityObservationState = .unknown,
                          facts: [IdentityEvidenceInput] = [], provenance: String = "synthetic",
                          completeness: SourceObservationCompleteness = .partial) throws -> SourceObservationEnvelope {
        try SourceObservationEnvelope(observation: observation(scope, state: state, provenance: provenance),
            evidence: facts, completeness: completeness)
    }
    private func event(target: PhysicalDrive? = nil, observationID: UUID? = nil, observationRevision: Int64 = 1,
                       revision: Int64 = 1, action: ManualAssociationAction = .associate) -> ManualDriveAssociation {
        let target = action == .revoke ? nil : (target ?? drive())
        return ManualDriveAssociation(operationID: uuid(300), observationID: observationID ?? uuid(100),
            observationRevision: observationRevision, revision: revision,
            previousEventID: revision > 1 ? uuid(301) : nil, target: target?.id, targetRevision: target?.revision,
            action: action, actor: "synthetic user", reason: "explicit generated choice", createdAt: "then")
    }
    func testNoEvidenceIsUnknown() throws {
        XCTAssertEqual(try SourceObservationResolver.resolve(envelope()).outcome, .unknown)
    }
    func testSameDisplayNameDistinctLocalRecordsNeverMatches() throws {
        XCTAssertNotEqual(drive().id, drive(2).id)
        let e = try envelope(facts: [fact(.displayName, "same")])
        XCTAssertEqual(try SourceObservationResolver.resolve(e).outcome, .unknown)
    }
    func testReusedMountPathHasNoIdentityOrIO() throws {
        let e = try envelope(.mountSession, facts: [fact(.mountPath, "/synthetic/never-open-this")])
        for _ in 0..<5 { XCTAssertEqual(try SourceObservationResolver.resolve(e).outcome, .unknown) }
    }
    func testReusedBSDNodeHasNoIdentity() throws {
        XCTAssertEqual(try SourceObservationResolver.resolve(envelope(.mountSession,
            facts: [fact(.bsdNode, "disk999s1")])).outcome, .unknown)
    }
    func testMissingAndMalformedUUID() throws {
        XCTAssertEqual(try SourceObservationResolver.resolve(envelope(facts: [fact(.filesystemUUID, nil,
            validation: .unknown)])).outcome, .unknown)
        for bad in ["", "not-a-uuid", "00000000-0000-0000-0000-000000000001 "] {
            XCTAssertThrowsError(try envelope(facts: [fact(.filesystemUUID, bad)]))
        }
    }
    func testClonedUUIDCandidateHypothesesRemainAmbiguous() throws {
        let e = try envelope(facts: [fact(.filesystemUUID, uuid(500).uuidString)])
        XCTAssertEqual(try SourceObservationResolver.resolve(e, candidates: [drive(), drive(2)]).outcome, .ambiguous)
        // A UUID does not perform a catalog lookup or manufacture a candidate.
        XCTAssertEqual(try SourceObservationResolver.resolve(e).candidateIDs, [])
    }
    func testDistinctPartitionsUnderOneGeneratedSessionStaySeparate() throws {
        let first = try envelope(.partition, facts: [fact(.partitionUUID, uuid(501).uuidString)])
        let second = try envelope(.partition, facts: [fact(.partitionUUID, uuid(502).uuidString)])
        XCTAssertNotEqual(first.evidence, second.evidence)
        XCTAssertEqual(first.observation.sessionID, second.observation.sessionID)
        for e in [first, second] { XCTAssertEqual(try SourceObservationResolver.resolve(e).outcome, .unknown) }
    }
    func testSameReaderDifferentMediaNeverSelectsDrive() throws {
        let reader = try envelope(.device, facts: [fact(.deviceSerial, "reader-serial")])
        let cardA = try envelope(.media, facts: [fact(.mediaUUID, uuid(501).uuidString)])
        let cardB = try envelope(.media, facts: [fact(.mediaUUID, uuid(502).uuidString)])
        for e in [reader, cardA, cardB] { XCTAssertEqual(try SourceObservationResolver.resolve(e).outcome, .unknown) }
    }
    func testIdenticalAliasesShareOneLineageWithoutPromotion() throws {
        let facts = [fact(.mediaUUID, uuid(500).uuidString, provider: .diskArbitration, property: "DA.media"),
            fact(.mediaUUID, uuid(500).uuidString.lowercased(), provider: .ioKit, property: "IO.media", validation: .validated)]
        let e = try envelope(.media, facts: facts)
        XCTAssertEqual(e.dependencyGroups, [IdentityEvidenceKind.mediaUUID.dependencyGroup])
        XCTAssertEqual(e, try envelope(.media, facts: facts.reversed()))
        XCTAssertEqual(try SourceObservationResolver.resolve(e, candidates: [drive()]).outcome, .unknown)
    }
    func testContradictoryAliasesConflictInBothOrders() throws {
        let facts = [fact(.filesystemUUID, uuid(500).uuidString, property: "A"),
            fact(.filesystemUUID, uuid(501).uuidString, provider: .foundation, property: "B")]
        for fs in [facts, facts.reversed()] {
            XCTAssertEqual(try SourceObservationResolver.resolve(envelope(facts: fs)).outcome, .conflict)
        }
    }
    func testMixedValidatedAndUnverifiedFieldsNeverVerifyHardware() throws {
        let e = try envelope(.device, facts: [fact(.deviceSerial, "serial", validation: .validated),
            fact(.vendorModel, "vendor/model")], completeness: .complete)
        XCTAssertEqual(try SourceObservationResolver.resolve(e, candidates: [drive()]).outcome, .unknown)
        XCTAssertFalse(drive().hardwareVerified)
    }
    func testDuplicateCandidateRecordsDeduplicateOrConflict() throws {
        let same = try SourceObservationResolver.resolve(envelope(), candidates: [drive(), drive()])
        XCTAssertEqual(same.outcome, .unknown); XCTAssertEqual(same.candidateIDs, [drive().id])
        XCTAssertEqual(try SourceObservationResolver.resolve(envelope(), candidates: [drive(), drive(revision: 2)]).outcome, .conflict)
    }
    func testSingleWeakPlausibleCandidateRemainsUnknown() throws {
        XCTAssertEqual(try SourceObservationResolver.resolve(envelope(), candidates: [drive()]).outcome, .unknown)
    }
    func testCurrentManualAssociationRemainsManual() throws {
        let result = try SourceObservationResolver.resolve(envelope(), association: event(), manualTarget: drive(), expectedAssociationRevision: 1)
        XCTAssertEqual(result.outcome, .manualAssociation(drive().id))
    }
    func testManualCorrectionSelectsExplicitIDDespiteAmbiguity() throws {
        let result = try SourceObservationResolver.resolve(envelope(state: .ambiguous), candidates: [drive(), drive(2)],
            association: event(target: drive(2), revision: 2, action: .correct), manualTarget: drive(2), expectedAssociationRevision: 2)
        XCTAssertEqual(result.outcome, .manualAssociation(drive(2).id))
    }
    func testRevocationDoesNotFallBackToOldTarget() throws {
        XCTAssertEqual(try SourceObservationResolver.resolve(envelope(), candidates: [drive()],
            association: event(revision: 2, action: .revoke), expectedAssociationRevision: 2).outcome, .unknown)
    }
    func testStaleObservationAndWrongSubjectConflict() throws {
        for e in [event(observationRevision: 2), event(observationID: uuid(999))] {
            XCTAssertEqual(try SourceObservationResolver.resolve(envelope(), association: e,
                manualTarget: drive(), expectedAssociationRevision: 1).outcome, .conflict)
        }
    }
    func testStaleTargetRevisionConflicts() throws {
        XCTAssertEqual(try SourceObservationResolver.resolve(envelope(), association: event(), manualTarget: drive(revision: 2),
            expectedAssociationRevision: 1).outcome, .conflict)
    }
    func testRetiredTargetConflicts() throws {
        XCTAssertEqual(try SourceObservationResolver.resolve(envelope(), association: event(), manualTarget: drive(retired: true),
            expectedAssociationRevision: 1).outcome, .conflict)
    }
    func testMissingTargetConflicts() throws {
        XCTAssertEqual(try SourceObservationResolver.resolve(envelope(), association: event(), expectedAssociationRevision: 1).outcome, .conflict)
    }
    func testContradictionWinsOverManualAndAllCandidateOrders() throws {
        let facts = [fact(.filesystemUUID, uuid(500).uuidString, property: "A"),
                     fact(.filesystemUUID, uuid(501).uuidString, property: "B")]
        for fs in [facts, facts.reversed()] {
            for candidates in [[drive(), drive(2)], [drive(2), drive()]] {
                XCTAssertEqual(try SourceObservationResolver.resolve(envelope(facts: fs), candidates: candidates,
                    association: event(), manualTarget: drive(), expectedAssociationRevision: 1).outcome, .conflict)
            }
        }
    }
    func testRepeatedAndReorderedGeneratedDeliveriesAreStateless() throws {
        let a = try envelope(); let b = try envelope(state: .ambiguous); let c = try envelope(state: .conflict)
        for inputs in [[a,b,c,a], [c,a,b,a], [b,c,a,a]] {
            for e in inputs {
                let result = try SourceObservationResolver.resolve(e)
                switch e.observation.state {
                case .unknown: XCTAssertEqual(result.outcome, .unknown)
                case .ambiguous: XCTAssertEqual(result.outcome, .ambiguous)
                case .conflict: XCTAssertEqual(result.outcome, .conflict)
                }
            }
        }
        XCTAssertEqual(a, try envelope())
    }
    func testPartialMissingProvenancePreservedAndManualNeverVerified() throws {
        let e = try envelope(facts: [fact(.filesystemUUID, nil, validation: .unknown, provenance: "")], provenance: "")
        XCTAssertTrue(e.hasUnknownProvenance); XCTAssertEqual(e.completeness, .partial)
        XCTAssertEqual(try SourceObservationResolver.resolve(e).outcome, .unknown)
        XCTAssertEqual(try SourceObservationResolver.resolve(e, association: event(), manualTarget: drive(),
            expectedAssociationRevision: 1).outcome, .manualAssociation(drive().id))
    }
    func testZeroProfilesAcrossEveryScopeAndOriginalState() throws {
        XCTAssertEqual(SourceObservationResolver.approvedRealStrongProfileCount, 0)
        for scope in IdentityScope.allCases {
            for state in [IdentityObservationState.unknown, .ambiguous, .conflict] {
                let result = try SourceObservationResolver.resolve(envelope(scope, state: state), candidates: [drive()])
                if case .uniqueStrongMatch = result.outcome { XCTFail("No approved profile") }
            }
        }
    }
    func testBoundedInputAndTypedValidation() throws {
        XCTAssertThrowsError(try SourceObservationEnvelope(observation: observation(revision: 0)))
        XCTAssertThrowsError(try envelope(facts: Array(repeating: fact(.displayName, "A"), count: 33)))
        XCTAssertThrowsError(try envelope(facts: [fact(.mediaUUID, uuid(500).uuidString)]))
        XCTAssertThrowsError(try envelope(facts: [fact(.displayName, String(repeating: "é", count: 513))]))
        XCTAssertThrowsError(try envelope(facts: [fact(.displayName, "has\0nul")]))
        XCTAssertThrowsError(try envelope(facts: [fact(.displayName, nil)]))
        XCTAssertThrowsError(try envelope(facts: [fact(.displayName, "A", validation: .unknown)]))
        XCTAssertThrowsError(try envelope(facts: [fact(.displayName, "A", property: String(repeating: "x", count: 257))]))
        XCTAssertThrowsError(try envelope(provenance: String(repeating: "x", count: 1025)))
        XCTAssertThrowsError(try SourceObservationResolver.resolve(envelope(), candidates: Array(repeating: drive(), count: 201)))
        XCTAssertThrowsError(try SourceObservationResolver.resolve(envelope(), expectedAssociationRevision: -1))
        let maximum = (0..<32).map { fact(.displayName, "A", property: "p\($0)") }
        XCTAssertEqual(try envelope(facts: maximum).evidence.count, 32)
        XCTAssertEqual(try envelope(facts: [fact(.displayName, "A"),fact(.displayName, "A")]).evidence.count, 1)
    }
    func testCandidateOrderingAndMaximumAreDeterministic() throws {
        let candidates = (1...200).map { drive($0) }
        let a = try SourceObservationResolver.resolve(envelope(), candidates: candidates)
        let b = try SourceObservationResolver.resolve(envelope(), candidates: candidates.reversed())
        XCTAssertEqual(a,b); XCTAssertEqual(a.outcome, .ambiguous); XCTAssertEqual(a.candidateIDs.count, 200)
        XCTAssertEqual(a.candidateIDs.map { $0.rawValue.uuidString }, a.candidateIDs.map { $0.rawValue.uuidString }.sorted())
    }
    func testExplicitConflictAndIncompleteCoverageNeverUseFallback() throws {
        let typed = try envelope(facts: [fact(.filesystemUUID, uuid(500).uuidString, validation: .conflict)])
        for e in [typed, try envelope(state: .conflict)] {
            XCTAssertEqual(try SourceObservationResolver.resolve(e, candidates: [drive()], association: event(),
                manualTarget: drive(), expectedAssociationRevision: 1).outcome, .conflict)
        }
        XCTAssertEqual(try SourceObservationResolver.resolve(envelope(), candidates: [drive()], association: event(),
            manualTarget: drive(), expectedAssociationRevision: 1, candidateCoverageComplete: false).outcome, .conflict)
    }
    func testStaleAssertionAndInvalidManualScopeFailClosed() throws {
        XCTAssertEqual(try SourceObservationResolver.resolve(envelope(), association: event(), manualTarget: drive(),
            expectedAssociationRevision: 0).outcome, .conflict)
        XCTAssertEqual(try SourceObservationResolver.resolve(envelope(.device), association: event(), manualTarget: drive(),
            expectedAssociationRevision: 1).outcome, .conflict)
        XCTAssertEqual(try SourceObservationResolver.resolve(envelope(), manualTarget: drive()).outcome, .conflict)
    }
}
