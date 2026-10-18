import XCTest
@testable import FSD

/// Generated, isolated v10 catalogs only. Paths in evidence are never opened.
final class SyntheticSourceResolutionRepositoryTests: XCTestCase {
    private var directory: URL!
    private var db: CatalogDatabase!
    private var identities: PhysicalDriveRepository!
    private var resolver: SyntheticSourceResolutionRepository!
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("FSD-task059-\(UUID())")
        db = try CatalogDatabase(url: directory.appendingPathComponent("generated.sqlite"), schemaURL: CatalogSchemaFixture.canonicalSchemaURL)
        identities = PhysicalDriveRepository(database: db); resolver = SyntheticSourceResolutionRepository(database: db)
    }
    override func tearDownWithError() throws {
        db?.close(); identities = nil; resolver = nil; db = nil
        try? FileManager.default.removeItem(at: directory)
    }
    private func observe(state: IdentityObservationState = .unknown, evidence: [IdentityEvidenceInput] = []) throws -> SourceObservationEnvelope {
        let o = try identities.recordObservation(sessionID: UUID(), revision: 7, scope: .volume, state: state,
            provenance: "generated", observedAt: Date(timeIntervalSince1970: 1_700_000_000), evidence: evidence)
        return try SourceObservationEnvelope(observation: o, evidence: evidence)
    }
    @discardableResult
    private func associate(_ e: SourceObservationEnvelope, _ d: PhysicalDrive?, revision: Int64 = 0,
                           action: ManualAssociationAction = .associate) throws -> ManualDriveAssociation {
        try identities.setManualAssociation(operationID: UUID(), observationID: e.observation.id,
            expectedObservationRevision: e.observation.revision, expectedAssociationRevision: revision,
            target: d?.id, expectedTargetRevision: d?.revision, action: action,
            actor: "synthetic user", reason: "deliberate generated choice")
    }
    private func rows() throws -> [String: [DatabaseRow]] {
        var result: [String: [DatabaseRow]] = [:]
        for table in CatalogMigrations.ExpectedState.tables { result[table] = try db.query("SELECT * FROM \(table) ORDER BY rowid") }
        return result
    }
    private func healthy() throws {
        XCTAssertEqual(try db.schemaVersion, 10)
        XCTAssertEqual(try db.scalar("PRAGMA foreign_keys")?.int64Value, 1)
        XCTAssertEqual(try db.scalar("PRAGMA integrity_check")?.stringValue, "ok")
        XCTAssertTrue(try db.query("PRAGMA foreign_key_check").isEmpty)
    }
    func testGeneratedRetryAndReorderedCandidatesHaveNoMutation() throws {
        let a = try identities.createDrive(label: "same", provenance: "synthetic A")
        let b = try identities.createDrive(label: "same", provenance: "synthetic B")
        let e = try observe()
        let before = try rows(); let changes = try db.scalar("SELECT total_changes()")
        for ids in [[a.id,b.id], [b.id,a.id,a.id], [a.id,b.id]] {
            let result = try resolver.resolve(e, expectedAssociationRevision: 0, candidateIDs: ids)
            XCTAssertEqual(result.outcome, .ambiguous)
            XCTAssertEqual(result.candidateIDs.count, 2)
        }
        XCTAssertEqual(try resolver.resolve(e, expectedAssociationRevision: 0).outcome, .unknown)
        XCTAssertEqual(try rows(), before); XCTAssertEqual(try db.scalar("SELECT total_changes()"), changes)
        try healthy()
    }
    func testCurrentCorrectionRevocationAndStaleAssertion() throws {
        let e = try observe(state: .ambiguous)
        let a = try identities.createDrive(provenance: "synthetic A")
        let b = try identities.createDrive(provenance: "synthetic B")
        let first = try associate(e,a)
        XCTAssertEqual(try resolver.resolve(e, expectedAssociationRevision: first.revision).outcome, .manualAssociation(a.id))
        let second = try associate(e,b,revision: first.revision,action: .correct)
        XCTAssertEqual(try resolver.resolve(e, expectedAssociationRevision: first.revision).outcome, .conflict)
        XCTAssertEqual(try resolver.resolve(e, expectedAssociationRevision: second.revision).outcome, .manualAssociation(b.id))
        let last = try associate(e,nil,revision: second.revision,action: .revoke)
        XCTAssertEqual(try resolver.resolve(e, expectedAssociationRevision: last.revision).outcome, .ambiguous)
        let history = try identities.associationHistory(observationID: e.observation.id).records
        XCTAssertEqual(history.map(\.action), [.associate,.correct,.revoke])
        XCTAssertEqual(history[1].previousEventID,first.operationID)
        XCTAssertEqual(history[2].previousEventID,second.operationID)
        let before = try rows()
        for revision in [0,1,2,3] { _ = try resolver.resolve(e, expectedAssociationRevision: Int64(revision)) }
        XCTAssertEqual(try rows(),before)
        try healthy()
    }
    func testStaleObservationSessionAndAlteredEvidenceConflictWithoutMutation() throws {
        let e = try observe(); let d = try identities.createDrive(provenance: "synthetic")
        try associate(e,d)
        let before = try rows()
        for (id,session,revision) in [(e.observation.id,e.observation.sessionID,Int64(8)),
            (e.observation.id,UUID(),Int64(7)), (UUID(),e.observation.sessionID,Int64(7))] {
            let altered = try SourceObservationEnvelope(observationID: id,sessionID: session,revision: revision,scope: .volume,
                provenance: e.observation.provenance,observedAt: Date(timeIntervalSince1970: 1_700_000_000))
            XCTAssertEqual(try resolver.resolve(altered,expectedAssociationRevision: 1).outcome,.conflict)
        }
        let contradiction = try SourceObservationEnvelope(observation: e.observation,evidence: [IdentityEvidenceInput(
            kind: .filesystemUUID,provider: .synthetic,property: "new contradiction",value: UUID().uuidString,
            validation: .conflict,provenance: "generated later fact")])
        XCTAssertEqual(try resolver.resolve(contradiction,expectedAssociationRevision: 1).outcome,.conflict)
        XCTAssertEqual(try rows(),before)
    }
    func testRetiredAndMissingReferencesFailClosed() throws {
        let e = try observe(); let d = try identities.createDrive(provenance: "synthetic")
        try associate(e,d)
        _ = try identities.retireDrive(id: d.id,expectedRevision: d.revision)
        let before = try rows()
        XCTAssertEqual(try resolver.resolve(e,expectedAssociationRevision: 1).outcome,.conflict)
        XCTAssertEqual(try resolver.resolve(e,expectedAssociationRevision: 1,candidateIDs: [PhysicalDriveID()]).outcome,.conflict)
        XCTAssertEqual(try rows(),before)
    }
    func testAliasCanonicalizationAndReopenReproduceResult() throws {
        let value = UUID().uuidString
        let facts = [IdentityEvidenceInput(kind: .filesystemUUID,provider: .synthetic,property: "A",value: value.lowercased(),provenance: "generated"),
                     IdentityEvidenceInput(kind: .filesystemUUID,provider: .foundation,property: "B",value: value,validation: .validated,provenance: "generated alias")]
        let e = try observe(evidence: facts); let d = try identities.createDrive(provenance: "synthetic")
        let association = try associate(e,d)
        let before = try rows()
        let expected = try resolver.resolve(e,expectedAssociationRevision: association.revision)
        db.close(); db = try CatalogDatabase(url: directory.appendingPathComponent("generated.sqlite"))
        identities = PhysicalDriveRepository(database: db); resolver = SyntheticSourceResolutionRepository(database: db)
        let observed = try XCTUnwrap(identities.observation(id: e.observation.id))
        let restored = try SourceObservationEnvelope(observation: observed,evidence: identities.evidence(observationID: observed.id).map(\.fact).reversed())
        XCTAssertEqual(e,restored)
        XCTAssertEqual(try resolver.resolve(restored,expectedAssociationRevision: association.revision),expected)
        XCTAssertEqual(try rows(),before)
        try healthy()
    }
    func testConflictingStoredEvidenceAndOriginalStateNeverFallback() throws {
        let value = UUID().uuidString
        let facts = [IdentityEvidenceInput(kind: .filesystemUUID,provider: .synthetic,property: "A",value: value,provenance: "generated"),
                     IdentityEvidenceInput(kind: .filesystemUUID,provider: .foundation,property: "B",value: UUID().uuidString,provenance: "generated")]
        let e = try observe(evidence: facts)
        let d = try identities.createDrive(provenance: "synthetic")
        for input in [e, try observe(state: .conflict)] {
            XCTAssertEqual(try resolver.resolve(input,expectedAssociationRevision: 0,candidateIDs: [d.id]).outcome,.conflict)
        }
        XCTAssertEqual(try resolver.resolve(observe(),expectedAssociationRevision: 0,candidateCoverageComplete: false).outcome,.conflict)
    }
    func testBoundsAndTransactionFailureLeaveConnectionUsable() throws {
        let e = try observe(); let before = try rows()
        XCTAssertThrowsError(try resolver.resolve(e,expectedAssociationRevision: -1))
        XCTAssertThrowsError(try resolver.resolve(e,expectedAssociationRevision: 0,candidateIDs: Array(repeating: PhysicalDriveID(),count: 201)))
        // Existing transaction rejects a nested BEGIN; no rollback of the caller's transaction.
        try db.transaction {
            XCTAssertThrowsError(try resolver.resolve(e,expectedAssociationRevision: 0))
            XCTAssertEqual(try db.scalar("SELECT 1")?.int64Value,1)
        }
        XCTAssertEqual(try resolver.resolve(e,expectedAssociationRevision: 0).outcome,.unknown)
        XCTAssertEqual(try rows(),before)
        try healthy()
    }
    func testSnapshotCollectionEntryAndTerminalComparisonFactsStayIdentical() throws {
        for statement in Self.syntheticHistory.split(separator: ";") {
            try db.execute(String(statement))
        }
        let before = try rows()
        let e = try observe(); let a = try identities.createDrive(provenance: "synthetic A")
        let b = try identities.createDrive(provenance: "synthetic B")
        for action in [ManualAssociationAction.associate,.correct,.revoke] {
            let revision: Int64 = action == .associate ? 0 : action == .correct ? 1 : 2
            _ = try associate(e,action == .revoke ? nil : action == .associate ? a : b,revision: revision,action: action)
            let current = try rows(); let changes = try db.scalar("SELECT total_changes()")
            _ = try resolver.resolve(e,expectedAssociationRevision: revision+1,candidateIDs: [a.id,b.id])
            XCTAssertEqual(try rows(),current)
            XCTAssertEqual(try db.scalar("SELECT total_changes()"),changes)
        }
        let after = try rows()
        for table in CatalogMigrations.ExpectedState.tables where !["physical_drives","identity_observations","identity_evidence","manual_drive_associations"].contains(table) {
            XCTAssertEqual(before[table],after[table],table)
        }
        XCTAssertThrowsError(try db.execute("UPDATE snapshots SET mount_path_at_capture='rewritten' WHERE id=1"))
        XCTAssertThrowsError(try db.execute("UPDATE entries SET name='rewritten' WHERE id=11"))
        XCTAssertThrowsError(try db.execute("UPDATE comparison_results SET display_name='rewritten'"))
        try healthy()
    }
    private static let syntheticHistory = """
        INSERT INTO collections(id,name,normalized_name,created_at,updated_at) VALUES (1,'Synthetic','synthetic','then','then');
        INSERT INTO volumes (id,display_name,persistent_uuid,first_seen_at,last_seen_at,created_at,updated_at)
        VALUES (1,'same','duplicate','then','then','then','then'),(2,'same','duplicate','then','then','then','then');
        INSERT INTO source_collection_defaults(source_kind,volume_id,collection_id,created_at,updated_at) VALUES ('volume',1,1,'then','then');
        INSERT INTO snapshots(id,volume_id,session_number,scan_root_name,status,scanner_version,schema_version,normalization_version,
            display_name,capture_policy_json,started_at,created_at,updated_at,collection_id,mount_path_at_capture,volume_display_name_at_capture)
        VALUES (1,1,1,'A','scanning','synthetic',9,'fsd-normalizer-v1_app-1.0_os-1','A','{}','then','then','then',1,'/synthetic/reused','old label'),
               (2,2,1,'B','scanning','synthetic',9,'fsd-normalizer-v1_app-1.0_os-1','B','{}','then','then','then',NULL,'/synthetic/reused',NULL);
        INSERT INTO entries(id,snapshot_id,parent_id,relative_path,case_preserving_path,case_folded_path,name,case_preserving_name,case_folded_name,item_type,sort_key,created_at)
        VALUES (11,1,NULL,'','','','A','A','a','directory','0','then'),(12,2,NULL,'','','','B','B','b','directory','0','then');
        INSERT INTO scan_issues(snapshot_id,relative_path,severity,source,message,was_skipped,created_at)
        VALUES (1,'','warning','scanner','synthetic',0,'then');
        INSERT INTO entry_classifications(entry_id,classification_run_id,created_at) VALUES (11,'synthetic','then');
        UPDATE snapshots SET status='complete',completed_at='then';
        INSERT INTO comparisons(id,left_snapshot_id,right_snapshot_id,profile_id,profile_version,status,matched_count,started_at,created_at)
        VALUES (1,1,2,1,1,'running',1,'then','then');
        INSERT INTO comparison_results(comparison_id,result_path,display_name,result_type,left_entry_id,right_entry_id,difference_flags,created_at)
        VALUES (1,'','A','matched',11,12,0,'then');
        INSERT INTO comparison_collision_groups(id,comparison_id,result_path,created_at) VALUES (1,1,'/synthetic/collision','then');
        INSERT INTO comparison_collision_members(id,group_id,side,entry_id,created_at) VALUES (1,1,'left',11,'then'),(2,1,'right',12,'then');
        UPDATE comparisons SET status='complete',completed_at='then';
        """
}
