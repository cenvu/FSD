import XCTest
import SQLite3
@testable import FSD

/// SYNTHETIC ONLY: generated catalogs/facts, never empirical device proof.
final class PhysicalDriveIdentityTests: XCTestCase {
    private var directory: URL!
    private var db: CatalogDatabase!
    private var repo: PhysicalDriveRepository!
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("FSD-task058-\(UUID())")
        db = try CatalogDatabase(url: directory.appendingPathComponent("synthetic.sqlite"), schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        repo = PhysicalDriveRepository(database: db)
    }
    override func tearDownWithError() throws {
        db?.close(); repo = nil; db = nil
        try? FileManager.default.removeItem(at: directory)
    }
    private func observe(scope: IdentityScope = .volume, state: IdentityObservationState = .unknown,
                         evidence: [IdentityEvidenceInput] = []) throws -> IdentityObservation {
        try repo.recordObservation(sessionID: UUID(), revision: 7, scope: scope, state: state,
            provenance: "synthetic fixture", observedAt: Date(timeIntervalSince1970: 1_700_000_000), evidence: evidence)
    }
    private func fact(_ value: String?, kind: IdentityEvidenceKind = .filesystemUUID,
                      provider: IdentityEvidenceProvider = .synthetic, property: String = "fixture.uuid",
                      validation: IdentityEvidenceValidation = .unverified) -> IdentityEvidenceInput {
        IdentityEvidenceInput(kind: kind, provider: provider, property: property, value: value,
            validation: validation, provenance: "generated test fact")
    }
    @discardableResult
    private func associate(_ observed: IdentityObservation, _ drive: PhysicalDrive?, revision: Int64 = 0,
                           action: ManualAssociationAction = .associate, operation: UUID = UUID()) throws -> ManualDriveAssociation {
        try repo.setManualAssociation(operationID: operation, observationID: observed.id, expectedObservationRevision: observed.revision,
            expectedAssociationRevision: revision, target: drive?.id, expectedTargetRevision: drive?.revision,
            action: action, actor: "synthetic user", reason: "deliberate synthetic selection")
    }
    private func count(_ table: String) throws -> Int64 {
        try XCTUnwrap(db.scalar("SELECT COUNT(*) FROM \(table)")?.int64Value)
    }
    private func healthy() throws {
        XCTAssertEqual(try db.scalar("PRAGMA integrity_check")?.stringValue,"ok")
        XCTAssertEqual(try db.scalar("PRAGMA foreign_keys")?.int64Value,1)
        XCTAssertTrue(try db.query("PRAGMA foreign_key_check").isEmpty)
    }
    func testSyntheticFreshIdentitySchema() throws {
        XCTAssertEqual(try db.schemaVersion,CatalogDatabase.currentSchemaVersion)
        for table in CatalogMigrations.identityTableDefinitions { XCTAssertEqual(try count(table.name),0) }
        try healthy()
    }
    func testOpaqueIDsSameLabelIdempotencyAndReopen() throws {
        let a = try repo.createDrive(label: "Same",provenance: "explicit A")
        let b = try repo.createDrive(label: "Same",provenance: "explicit A")
        XCTAssertNotEqual(a.id,b.id); XCTAssertFalse(a.hardwareVerified)
        XCTAssertEqual(try repo.createDrive(id: a.id,label: "Same",provenance: "explicit A"),a)
        XCTAssertThrowsError(try repo.createDrive(id: a.id,label: "changed",provenance: "explicit A"))
        XCTAssertEqual(try count("physical_drives"),2)
        db.close(); db = try CatalogDatabase(url: directory.appendingPathComponent("synthetic.sqlite"))
        repo = PhysicalDriveRepository(database: db)
        XCTAssertEqual(try repo.drive(id: a.id),a); XCTAssertEqual(try repo.drive(id: b.id),b)
    }
    func testExplicitAssociationAndExactRetry() throws {
        let a = try repo.createDrive(provenance: "manual")
        let o = try observe(); let operation = UUID()
        XCTAssertEqual(try repo.resolution(observationID: o.id),.unknown)
        let result = try associate(o,a,operation: operation)
        XCTAssertEqual(try associate(o,a,operation: operation),result)
        XCTAssertEqual(try count("manual_drive_associations"),1)
        XCTAssertEqual(try repo.resolution(observationID: o.id),.manualAssociation(a.id))
        XCTAssertThrowsError(try associate(o,a,revision: 1,action: .correct,operation: operation))
    }
    func testInvalidTargetsAndStaleRevisionsNeverMutate() throws {
        let a = try repo.createDrive(provenance: "manual"); let o = try observe()
        XCTAssertThrowsError(try repo.setManualAssociation(operationID: UUID(),observationID: o.id,expectedObservationRevision: o.revision,
            expectedAssociationRevision: 0,target: PhysicalDriveID(),expectedTargetRevision: 1,action: .associate,actor: "user",reason: "missing"))
        for (observationID,observationRevision,targetRevision) in [(UUID(),7,1),(o.id,6,1),(o.id,7,2)] {
            XCTAssertThrowsError(try repo.setManualAssociation(operationID: UUID(),observationID: observationID,
                expectedObservationRevision: Int64(observationRevision),expectedAssociationRevision: 0,target: a.id,
                expectedTargetRevision: Int64(targetRevision),action: .associate,actor: "user",reason: "stale"))
        }
        XCTAssertEqual(try count("manual_drive_associations"),0)
        try associate(o,a)
        XCTAssertThrowsError(try associate(o,a)); XCTAssertThrowsError(try associate(o,a,revision: 0,action: .correct))
        XCTAssertEqual(try count("manual_drive_associations"),1)
    }
    func testCorrectionRevocationAndReassociationRetainProvenance() throws {
        let a = try repo.createDrive(provenance: "A"); let b = try repo.createDrive(provenance: "B"); let o = try observe()
        let original = try associate(o,a)
        let corrected = try associate(o,b,revision: 1,action: .correct)
        XCTAssertEqual(corrected.previousEventID,original.operationID)
        XCTAssertEqual(try repo.resolution(observationID: o.id),.manualAssociation(b.id))
        let revoked = try associate(o,nil,revision: 2,action: .revoke)
        XCTAssertEqual(revoked.previousEventID,corrected.operationID)
        XCTAssertEqual(try repo.resolution(observationID: o.id),.unknown)
        let history = try repo.associationHistory(observationID: o.id)
        XCTAssertEqual(history.records,[original,corrected,revoked])
        XCTAssertTrue(history.records.allSatisfy { !$0.actor.isEmpty && !$0.reason.isEmpty })
        try associate(o,a,revision: 3,action: .correct)
        XCTAssertEqual(try repo.resolution(observationID: o.id),.manualAssociation(a.id))
    }
    func testNoNameUUIDPathFallbackOrStrongMatch() throws {
        _ = try repo.createDrive(label: "Same",provenance: "manual")
        let uuid = UUID().uuidString
        let observations = try [observe(evidence: [fact(uuid)]),observe(evidence: [fact(uuid)]),
            observe(evidence: [fact(nil,validation: .unknown)]),
            observe(scope: .mountSession,evidence: [fact("/synthetic/reused",kind: .mountPath)]),
            observe(scope: .mountSession,evidence: [fact("/synthetic/reused",kind: .mountPath)]),
            observe(evidence: [fact("Same",kind: .displayName)])]
        for o in observations { XCTAssertEqual(try repo.resolution(observationID: o.id),.unknown) }
        XCTAssertEqual(try count("physical_drives"),1); XCTAssertEqual(try count("manual_drive_associations"),0)
        XCTAssertEqual(PhysicalDriveRepository.approvedRealStrongProfileCount,0)
    }
    func testUnknownAmbiguousConflictRemainUnverified() throws {
        let a = try repo.createDrive(provenance: "manual")
        let unknown = try observe(); let ambiguous = try observe(state: .ambiguous); let conflict = try observe(state: .conflict)
        XCTAssertEqual(try repo.resolution(observationID: unknown.id),.unknown)
        XCTAssertEqual(try repo.resolution(observationID: ambiguous.id),.ambiguous)
        XCTAssertEqual(try repo.resolution(observationID: conflict.id),.conflict)
        XCTAssertThrowsError(try associate(conflict,a))
        try associate(ambiguous,a)
        XCTAssertEqual(try repo.resolution(observationID: ambiguous.id),.manualAssociation(a.id))
        let newer = try observe(); XCTAssertEqual(try repo.resolution(observationID: newer.id),.unknown)
    }
    func testTypedEvidenceRoundTripsEveryScopeAndProvenance() throws {
        for kind in IdentityEvidenceKind.allCases {
            let value = kind.isUUID ? UUID().uuidString : "synthetic-value"
            let input = fact(value,kind: kind,validation: .validated)
            let o = try observe(scope: kind.scope,evidence: [input])
            let stored = try XCTUnwrap(repo.evidence(observationID: o.id).first)
            XCTAssertEqual(stored.fact,input); XCTAssertEqual(stored.scope,kind.scope)
            XCTAssertEqual(stored.observationRevision,7); XCTAssertEqual(stored.observedAt,o.observedAt)
            XCTAssertEqual(stored.dependencyGroup,kind.dependencyGroup)
            XCTAssertEqual(try repo.resolution(observationID: o.id),.unknown)
        }
    }
    func testMalformedOversizedAndWrongScopeEvidenceRejectedAtomically() throws {
        for bad in [fact("not-a-uuid"),fact(String(repeating: "a",count: 1025),kind: .displayName),
                    fact("has\0nul",kind: .displayName),fact(nil),fact(UUID().uuidString,validation: .unknown),fact("  ",kind: .displayName)] {
            XCTAssertThrowsError(try observe(evidence: [bad]))
        }
        XCTAssertThrowsError(try observe(scope: .device,evidence: [fact(UUID().uuidString)]))
        XCTAssertThrowsError(try observe(evidence: Array(repeating: fact(UUID().uuidString),count: 33)))
        XCTAssertThrowsError(try observe(evidence: [fact(UUID().uuidString),fact(UUID().uuidString)]))
        XCTAssertEqual(try count("identity_observations"),0); XCTAssertEqual(try count("identity_evidence"),0)
    }
    func testAliasesShareDependencyAndContradictionsFailClosed() throws {
        let uuid = UUID().uuidString
        let o = try observe(scope: .media,evidence: [fact(uuid,kind: .mediaUUID,provider: .diskArbitration,property: "DAMediaUUID"),
            fact(uuid.lowercased(),kind: .mediaUUID,provider: .ioKit,property: "IOMediaUUID")])
        let facts = try repo.evidence(observationID: o.id)
        XCTAssertEqual(Set(facts.map(\.dependencyGroup)).count,1)
        XCTAssertEqual(try repo.resolution(observationID: o.id),.unknown)
        let contradictory = try observe(evidence: [fact(uuid,provider: .diskArbitration),fact(UUID().uuidString,provider: .foundation)])
        XCTAssertEqual(try repo.resolution(observationID: contradictory.id),.conflict)
        let a = try repo.createDrive(provenance: "manual")
        XCTAssertThrowsError(try associate(contradictory,a))
        let explicitlyConflicting = try observe(evidence: [fact(uuid,validation: .conflict)])
        XCTAssertEqual(try repo.resolution(observationID: explicitlyConflicting.id),.conflict)
    }
    func testRetirementIsRevisionProtectedAndHistoryCannotBeDeleted() throws {
        let a = try repo.createDrive(provenance: "manual"); let o = try observe(); let event = try associate(o,a)
        XCTAssertThrowsError(try repo.retireDrive(id: a.id,expectedRevision: 2))
        let retired = try repo.retireDrive(id: a.id,expectedRevision: 1)
        XCTAssertEqual(retired.revision,2); XCTAssertTrue(retired.retired)
        XCTAssertEqual(try repo.resolution(observationID: o.id),.conflict)
        XCTAssertEqual(try repo.latestAssociation(observationID: o.id),event)
        XCTAssertThrowsError(try associate(observe(),retired))
        XCTAssertThrowsError(try repo.retireDrive(id: a.id,expectedRevision: 2))
        for table in ["physical_drives","identity_observations","manual_drive_associations"] {
            XCTAssertThrowsError(try db.execute("DELETE FROM \(table)"))
        }
        XCTAssertThrowsError(try db.execute("UPDATE physical_drives SET retired=0,revision=3"))
        XCTAssertThrowsError(try db.execute("UPDATE manual_drive_associations SET reason='rewritten'"))
        XCTAssertThrowsError(try db.execute("UPDATE identity_observations SET state='unknown'"))
        try associate(o,nil,revision: 1,action: .revoke)
        try healthy()
    }
    func testObservationEvidenceTransactionFailureRollsBack() throws {
        try db.execute("CREATE TRIGGER fixture_failure BEFORE INSERT ON identity_evidence BEGIN SELECT RAISE(ABORT,'synthetic failure'); END")
        XCTAssertThrowsError(try observe(evidence: [fact(UUID().uuidString)]))
        XCTAssertEqual(try count("identity_observations"),0); XCTAssertEqual(try count("identity_evidence"),0)
        try db.execute("DROP TRIGGER fixture_failure")
        let o = try observe(evidence: [fact(UUID().uuidString)])
        XCTAssertThrowsError(try db.execute("UPDATE identity_evidence SET provenance='rewrite'"))
        XCTAssertThrowsError(try db.execute("DELETE FROM identity_evidence"))
        let a = try repo.createDrive(provenance: "manual")
        try db.execute("CREATE TRIGGER fixture_event_failure BEFORE INSERT ON manual_drive_associations BEGIN SELECT RAISE(ABORT,'synthetic failure'); END")
        XCTAssertThrowsError(try associate(o,a)); XCTAssertEqual(try count("manual_drive_associations"),0)
        try db.execute("DROP TRIGGER fixture_event_failure"); try associate(o,a)
        try healthy()
    }
    func testForeignKeyViolationAndOuterTransactionRollBack() throws {
        XCTAssertThrowsError(try db.transaction {
            try db.execute("INSERT INTO physical_drives(id,admission,provenance,created_at,updated_at) VALUES (?,'explicit_local','synthetic','now','now')",bindings: [.text(UUID().uuidString)])
            // An invalid first revoke is rejected by the admission trigger.
            try db.execute("""
                INSERT INTO manual_drive_associations(id,observation_id,observation_revision,revision,action,actor,reason,created_at)
                VALUES (?,?,1,1,'revoke','user','invalid','now')
                """,bindings: [.text(UUID().uuidString),.text(UUID().uuidString)])
        })
        XCTAssertEqual(try count("physical_drives"),0)
        // Missing-observation evidence is rejected by the scope trigger.
        // Actual composite FK coverage is in the dedicated revision test below.
        XCTAssertThrowsError(try db.execute("""
            INSERT INTO identity_evidence(id,observation_id,observation_revision,scope,kind,provider,property,dependency_group,value,validation,provenance,observed_at)
            VALUES (?, ?,1,'volume','displayName','synthetic','name','displayName','name','unverified','test','now')
            """,bindings: [.text(UUID().uuidString),.text(UUID().uuidString)]))
        try healthy()
    }
    func testCompositeObservationForeignKeyRejectsWrongRevision() throws {
        let drive = try repo.createDrive(provenance: "synthetic")
        let o = try observe(); let first = try associate(o,drive)
        let before = try count("physical_drives")
        XCTAssertThrowsError(try db.transaction {
            try db.execute("INSERT INTO physical_drives(id,admission,provenance,created_at,updated_at) VALUES (?,'explicit_local','synthetic','now','now')",bindings: [.text(UUID().uuidString)])
            // All admission-trigger checks pass; only the composite FK rejects
            // revision 999 for this real observation ID.
            try db.execute("""
                INSERT INTO manual_drive_associations(id,observation_id,observation_revision,revision,previous_event_id,action,actor,reason,created_at)
                VALUES (?,?,999,2,?,'revoke','user','synthetic FK failure','now')
                """,bindings: [.text(UUID().uuidString),.text(o.id.uuidString),.text(first.operationID.uuidString)])
        }) { error in
            guard case let CatalogDatabaseError.sqlite(code,message) = error else { return XCTFail("\(error)") }
            XCTAssertEqual(code,SQLITE_CONSTRAINT)
            XCTAssertTrue(message.contains("FOREIGN KEY constraint failed"),message)
        }
        XCTAssertEqual(try count("physical_drives"),before)
        XCTAssertEqual(try count("manual_drive_associations"),1)
        XCTAssertEqual(try repo.resolution(observationID: o.id),.manualAssociation(drive.id))
        try healthy()
    }
    func testStaleWriterOnSeparateConnectionCannotOverwriteCorrection() throws {
        let drive = try repo.createDrive(provenance: "synthetic")
        let o = try observe(); try associate(o,drive)
        let otherDB = try CatalogDatabase(url: db.url); defer { otherDB.close() }
        let other = PhysicalDriveRepository(database: otherDB)
        let stale = try XCTUnwrap(other.latestAssociation(observationID: o.id))
        try associate(o,nil,revision: 1,action: .revoke)
        XCTAssertThrowsError(try other.setManualAssociation(operationID: UUID(),observationID: o.id,expectedObservationRevision: o.revision,
            expectedAssociationRevision: stale.revision,target: drive.id,expectedTargetRevision: drive.revision,
            action: .correct,actor: "stale user",reason: "stale")) { error in
            XCTAssertEqual(error as? PhysicalDriveIdentityError,.staleRevision)
        }
        XCTAssertEqual(try count("manual_drive_associations"),2)
        XCTAssertEqual(try repo.resolution(observationID: o.id),.unknown)
    }

    func testBoundedDeterministicReadsUseIndexes() throws {
        for _ in 0..<205 { _ = try repo.createDrive(label: "same",provenance: "synthetic") }
        let page = try repo.drives(limit: Int.max)
        XCTAssertEqual(page.records.count,200); XCTAssertTrue(page.isTruncated)
        XCTAssertEqual(page.records.map(\.id.rawValue.uuidString),page.records.map(\.id.rawValue.uuidString).sorted())
        let next = try repo.drives(after: page.records.last?.id,limit: Int.max)
        XCTAssertEqual(next.records.count,5); XCTAssertFalse(next.isTruncated)
        XCTAssertEqual(try repo.drives(limit: Int.min).records.count,1)
        let o = try observe(); let a = page.records[0]
        for revision in 0..<5 { try associate(o,a,revision: Int64(revision),action: revision == 0 ? .associate : .correct) }
        let history = try repo.associationHistory(observationID: o.id,limit: 2)
        XCTAssertEqual(history.records.map(\.revision),[1,2]); XCTAssertTrue(history.isTruncated)
        XCTAssertEqual(try repo.associationHistory(observationID: o.id,afterRevision: 2,limit: 2).records.map(\.revision),[3,4])
        for (sql,index) in [("SELECT * FROM manual_drive_associations WHERE observation_id='x' ORDER BY revision DESC LIMIT 1","idx_manual_associations_observation"),
                            ("SELECT * FROM identity_evidence WHERE observation_id='x' ORDER BY id LIMIT 33","idx_identity_evidence_observation"),
                            ("SELECT * FROM physical_drives WHERE id > 'x' ORDER BY id LIMIT 201","sqlite_autoindex_physical_drives_1")] {
            XCTAssertTrue(try db.query("EXPLAIN QUERY PLAN " + sql).contains { $0["detail"]?.stringValue?.contains(index) == true })
        }
    }
}
