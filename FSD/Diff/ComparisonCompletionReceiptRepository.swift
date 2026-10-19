import Foundation
import CryptoKit

/// Offline, metadata-only completion evidence. No public write/backfill API.
/// Reads never join the mutable profile, volume registry or scan-issue tables.
public final class ComparisonCompletionReceiptRepository {
    private let database: CatalogDatabase
    public init(database: CatalogDatabase) { self.database = database }

    public func receipt(comparisonID: ComparisonID) throws -> ComparisonCompletionReceipt? {
        try database.transaction { try validatedReceipt(comparisonID: comparisonID) }
    }

    /// Internal Save seam: caller already owns one BEGIN IMMEDIATE transaction.
    /// Checkpoints include receipt closure validation in the operation budget.
    func validatedReceipt(comparisonID: ComparisonID, checkpoint: () throws -> Void = {}) throws -> ComparisonCompletionReceipt? {
        try checkpoint()
        guard let row = try database.query("SELECT * FROM comparison_completion_receipts WHERE comparison_id=?", bindings:[.integer(comparisonID.rawValue)]).first else { return nil }
        guard case .blob(let data) = row["payload"] else { throw CompletionReceiptError.invalidEvidence("Missing receipt encoding") }
        let receipt = try ComparisonCompletionReceipt.decode(data)
        try validateBinding(receipt, row: row, checkpoint: checkpoint)
        return receipt
    }
    public func isEligibleForExactSave(comparisonID: ComparisonID) throws -> Bool {
        try receipt(comparisonID: comparisonID) != nil
    }

    /// Caller holds the cancellation finalization lock. The insert's SQL trigger
    /// performs the successful status transition in this same transaction. A
    /// statement/trigger/commit failure rolls back receipt and terminal status.
    /// No cancelled/failed/running receipt can commit; no terminal backfill.
    func complete(comparisonID: ComparisonID, profile: ComparisonProfile, key: String, warnings: [String], leftUsed: SnapshotSummary, rightUsed: SnapshotSummary) throws {
        try database.transaction {
            guard let comparison = try database.query("SELECT * FROM comparisons WHERE id=? AND status='running'",bindings:[.integer(comparisonID.rawValue)]).first,
                  comparison["profile_id"]?.int64Value == profile.id, comparison["profile_version"]?.int64Value == profile.version,
                  comparison["left_snapshot_id"]?.int64Value == leftUsed.id.rawValue,
                  comparison["right_snapshot_id"]?.int64Value == rightUsed.id.rawValue,
                  let started = comparison["started_at"]?.stringValue,
                  let created = comparison["created_at"]?.stringValue else { throw CompletionReceiptError.staleComparison }
            let left = try side(id: leftUsed.id.rawValue)
            let right = try side(id: rightUsed.id.rawValue)
            // Bind the actually selected engine policy to protected capture facts.
            let selection = ComparisonEngine.selectedKey(left: leftUsed, right: rightUsed)
            guard selection.column == key, selection.warnings == warnings,
                  leftUsed.normalizationVersion == rightUsed.normalizationVersion,
                  left.header["source_case_sensitivity"]?.text == leftUsed.capture.caseSensitivity.rawValue,
                  right.header["source_case_sensitivity"]?.text == rightUsed.capture.caseSensitivity.rawValue else { throw CompletionReceiptError.invalidEvidence("Changed executed side policy") }
            guard let generationRaw = try database.scalar("SELECT generation FROM comparison_receipt_catalog WHERE singleton=1")?.stringValue,
                  let generation = UUID(uuidString:generationRaw),
                  let time = try database.scalar("SELECT CURRENT_TIMESTAMP")?.stringValue else { throw CompletionReceiptError.invalidEvidence("Missing completion identity") }
            let receipt = ComparisonCompletionReceipt(
                version:1, encoding:"fsd-receipt-json-utf8-v1", catalogGeneration:generation, completionToken:UUID(), comparisonID:comparisonID.rawValue,
                status:"complete", orientation:"left-reference_right-changed-v1", startedAt:started, comparisonCreatedAt:created, completedAt:time,
                profile:CompletionProfileDefinition(profile), engineVersion:"fsd-metadata-engine-v1", identitySelectionVersion:"adr010-v1",
                ignoreRuleVersion:"fsd-ignore-glob-v1", normalizationVersion:leftUsed.normalizationVersion.rawValue, selectedPathKey:key,
                warningVersion:"adr010-warning-text-v1", warnings:warnings, validationVersion:"fsd-result-closure-v1",
                left:left, right:right, closure:try closure(comparisonID:comparisonID.rawValue, leftID:leftUsed.id.rawValue, rightID:rightUsed.id.rawValue))
            let data = try receipt.encoded()
            try database.execute("""
                INSERT INTO comparison_completion_receipts(comparison_id,catalog_generation,completion_token,receipt_version,encoding,completed_at,
                  left_snapshot_id,right_snapshot_id,profile_id,profile_revision,matched_count,added_count,removed_count,changed_count,uncertain_count,payload)
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
                """,bindings:[.integer(receipt.comparisonID),.text(generationRaw),.text(receipt.completionToken.uuidString),.integer(1),.text(receipt.encoding),.text(time),
                    .integer(leftUsed.id.rawValue),.integer(rightUsed.id.rawValue),.integer(profile.id),.integer(profile.version),
                    .integer(receipt.closure.counts["matched"]!),.integer(receipt.closure.counts["added"]!),.integer(receipt.closure.counts["removed"]!),
                    .integer(receipt.closure.counts["changed"]!),.integer(receipt.closure.counts["uncertain"]!),.blob(data)])
            guard let stored = try database.query("SELECT * FROM comparison_completion_receipts WHERE comparison_id=?",bindings:[.integer(comparisonID.rawValue)]).first else { throw CompletionReceiptError.staleComparison }
            try validateBinding(receipt,row:stored)
        }
    }

    private func validateBinding(_ receipt: ComparisonCompletionReceipt, row: DatabaseRow, checkpoint: () throws -> Void = {}) throws {
        guard receipt.comparisonID == row["comparison_id"]?.int64Value,
              receipt.catalogGeneration == row["catalog_generation"]?.stringValue.flatMap(UUID.init(uuidString:)),
              receipt.completionToken == row["completion_token"]?.stringValue.flatMap(UUID.init(uuidString:)),
              row["receipt_version"]?.int64Value == 1, row["encoding"]?.stringValue == receipt.encoding,
              row["completed_at"]?.stringValue == receipt.completedAt,
              row["left_snapshot_id"]?.int64Value == receipt.left.header["id"]?.integer,
              row["right_snapshot_id"]?.int64Value == receipt.right.header["id"]?.integer,
              row["profile_id"]?.int64Value == receipt.profile.id, row["profile_revision"]?.int64Value == receipt.profile.revision,
              let c = try database.query("SELECT * FROM comparisons WHERE id=?",bindings:[.integer(receipt.comparisonID)]).first,
              c["status"]?.stringValue == "complete", c["left_snapshot_id"] == row["left_snapshot_id"], c["right_snapshot_id"] == row["right_snapshot_id"],
              c["profile_id"] == row["profile_id"], c["profile_version"] == row["profile_revision"], c["completed_at"] == row["completed_at"],
              c["started_at"]?.stringValue == receipt.startedAt, c["created_at"]?.stringValue == receipt.comparisonCreatedAt else { throw CompletionReceiptError.invalidEvidence("Receipt identity mismatch") }
        for type in ["matched","added","removed","changed","uncertain"] {
            guard row[type+"_count"]?.int64Value == receipt.closure.counts[type], c[type+"_count"] == row[type+"_count"] else { throw CompletionReceiptError.invalidEvidence("Receipt counts mismatch") }
        }
        // Compare only immutable terminal rows. Mutable current side/profile
        // annotations/issues never participate in this future-Save eligibility.
        guard try closure(comparisonID:receipt.comparisonID, leftID:receipt.left.header["id"]!.integer!, rightID:receipt.right.header["id"]!.integer!, checkpoint: checkpoint) == receipt.closure else { throw CompletionReceiptError.invalidEvidence("Persisted terminal closure differs") }
    }

    private func side(id: Int64) throws -> CompletionSnapshotEvidence {
        let headerRows = try metadataRows(table:"snapshots", columns:CompletionEvidenceContract.snapshotColumns, predicate:"id=?", bindings:[.integer(id)], limit:1)
        guard let header = headerRows.first else { throw CompletionReceiptError.invalidEvidence("Missing snapshot") }
        let count = try database.scalar("SELECT COUNT(*) FROM scan_issues WHERE snapshot_id=?",bindings:[.integer(id)])?.int64Value ?? 0
        guard count <= ComparisonCompletionReceipt.maximumIssuesPerSide else { throw CompletionReceiptError.metadataLimit }
        guard try database.scalar("SELECT 1 FROM scan_issues i LEFT JOIN entries e ON e.id=i.entry_id WHERE i.snapshot_id=? AND i.entry_id IS NOT NULL AND e.snapshot_id IS NOT i.snapshot_id LIMIT 1",bindings:[.integer(id)]) == nil else { throw CompletionReceiptError.invalidEvidence("Cross-side issue entry") }
        var issues: [[String:CompletionMetadataValue]] = []
        var cursor: Int64 = 0
        var bytes = try ComparisonCompletionReceipt.encoder().encode(header).count
        while true {
            let page = try metadataRows(table:"scan_issues",columns:CompletionEvidenceContract.issueColumns,predicate:"snapshot_id=? AND id>?",bindings:[.integer(id),.integer(cursor)],limit:256)
            if page.isEmpty { break }
            for issue in page {
                guard let issueID = issue["id"]?.integer else { throw CompletionReceiptError.invalidEvidence("Missing issue ID") }
                bytes += try ComparisonCompletionReceipt.encoder().encode(issue).count
                guard bytes <= ComparisonCompletionReceipt.maximumBytes else { throw CompletionReceiptError.metadataLimit }
                issues.append(issue); cursor = issueID
            }
        }
        guard Int64(issues.count) == count else { throw CompletionReceiptError.invalidEvidence("Incomplete issues") }
        let side = CompletionSnapshotEvidence(header:header,issues:issues)
        try CompletionEvidenceContract.validate(side)
        return side
    }

    /// Check byte sizes before selecting large values. SQL hex is compared with
    /// decoded TEXT bytes so invalid UTF8 and embedded NUL cannot silently become
    /// a different string through SQLite's general catalog String(cString:) API.
    private func metadataRows(table: String, columns: [String:String], predicate: String, bindings: [DatabaseValue], limit: Int) throws -> [[String:CompletionMetadataValue]] {
        let names = columns.keys.sorted()
        let bad = names.map { "length(CAST(\($0) AS BLOB))>65536" }.joined(separator:" OR ")
        guard try database.scalar("SELECT 1 FROM (SELECT * FROM \(table) WHERE \(predicate) ORDER BY id LIMIT \(limit)) WHERE \(bad) LIMIT 1",bindings:bindings) == nil else { throw CompletionReceiptError.metadataLimit }
        let projection = names.flatMap { name in columns[name] == "text" ? [name,"hex(CAST(\(name) AS BLOB)) AS raw_\(name)"] : [name] }.joined(separator:",")
        return try database.query("SELECT \(projection) FROM \(table) WHERE \(predicate) ORDER BY id LIMIT \(limit)",bindings:bindings).map { row in
            var result: [String:CompletionMetadataValue] = [:]
            for name in names {
                guard let value = row[name] else { throw CompletionReceiptError.invalidEvidence("Missing metadata field") }
                if case .text(let text) = value {
                    let expected = CompletionEvidenceContract.hexUTF8(text)
                    guard row["raw_"+name]?.stringValue == expected else { throw CompletionReceiptError.invalidEvidence("Invalid UTF8 metadata") }
                }
                result[name] = try CompletionMetadataValue(value)
            }
            return result
        }
    }

    enum CompletionSide: String { case left, right }
    static func coverageSQL(side: CompletionSide) -> String {
        """
        SELECT 1 FROM entries e WHERE e.snapshot_id=? AND
          ((SELECT COUNT(*) FROM comparison_results r WHERE r.comparison_id=? AND r.\(side.rawValue)_entry_id=e.id)
           + (SELECT COUNT(*) FROM comparison_collision_members m JOIN comparison_collision_groups g ON g.id=m.group_id
              WHERE m.entry_id=e.id AND m.side='\(side.rawValue)' AND g.comparison_id=?)) != 1 LIMIT 1
        """
    }

    /// Bounded Swift memory: stream canonical metadata pages into a framed
    /// digest. SQL ownership/coverage checks reject missing, duplicate, foreign
    /// and orphaned links rather than guessing a complete result universe.
    private func closure(comparisonID: Int64, leftID: Int64, rightID: Int64, checkpoint: () throws -> Void = {}) throws -> CompletionResultClosure {
        try checkpoint()
        let binding: [DatabaseValue] = [.integer(comparisonID)]
        var counts = Dictionary(uniqueKeysWithValues:ComparisonResultType.allCases.map { ($0.rawValue,Int64(0)) })
        for row in try database.query("SELECT result_type,COUNT(*) n FROM comparison_results WHERE comparison_id=? GROUP BY result_type",bindings:binding) {
            guard let type = row["result_type"]?.stringValue, counts[type] != nil, let n = row["n"]?.int64Value else { throw CompletionReceiptError.invalidEvidence("Unknown result kind") }; counts[type] = n
        }
        for (side,snapshot) in [(CompletionSide.left,leftID),(CompletionSide.right,rightID)] {
            try checkpoint()
            guard try database.scalar(Self.coverageSQL(side:side),bindings:[.integer(snapshot),.integer(comparisonID),.integer(comparisonID)]) == nil else {
                throw CompletionReceiptError.invalidEvidence("Missing or duplicate result entry")
            }
            let ordinary = try database.scalar("SELECT COUNT(*) FROM comparison_results WHERE comparison_id=? AND \(side.rawValue)_entry_id IS NOT NULL",bindings:binding)?.int64Value ?? 0
            let members = try database.scalar("SELECT COUNT(*) FROM comparison_collision_members m JOIN comparison_collision_groups g ON g.id=m.group_id WHERE g.comparison_id=? AND m.side=?",bindings:binding+[.text(side.rawValue)])?.int64Value ?? 0
            let entries = try database.scalar("SELECT COUNT(*) FROM entries WHERE snapshot_id=?",bindings:[.integer(snapshot)])?.int64Value ?? 0
            let (total,overflow) = ordinary.addingReportingOverflow(members)
            guard !overflow, total == entries, entries > 0 else { throw CompletionReceiptError.invalidEvidence("Foreign or missing result side") }
        }
        guard try database.scalar("""
            SELECT 1 FROM comparison_results r LEFT JOIN comparison_results p ON p.id=r.parent_result_id
            WHERE r.comparison_id=? AND ((r.parent_result_id IS NOT NULL AND (p.comparison_id IS NOT r.comparison_id OR p.id>=r.id))
              OR (r.left_entry_id IS NULL AND r.right_entry_id IS NULL AND (r.result_type!='uncertain' OR NOT EXISTS
                 (SELECT 1 FROM comparison_collision_groups g WHERE g.comparison_id=r.comparison_id AND g.result_path=r.result_path)))) LIMIT 1
            """,bindings:binding) == nil else { throw CompletionReceiptError.invalidEvidence("Unclosed result graph") }
        guard try database.scalar("""
            SELECT 1 FROM comparison_collision_groups g WHERE g.comparison_id=? AND
              ((SELECT COUNT(*) FROM comparison_collision_members m WHERE m.group_id=g.id)<3 OR
               NOT EXISTS (SELECT 1 FROM comparison_collision_members m WHERE m.group_id=g.id AND m.side='left') OR
               NOT EXISTS (SELECT 1 FROM comparison_collision_members m WHERE m.group_id=g.id AND m.side='right') OR
               (SELECT COUNT(*) FROM comparison_results r WHERE r.comparison_id=g.comparison_id AND r.result_path=g.result_path AND r.result_type='uncertain' AND r.left_entry_id IS NULL AND r.right_entry_id IS NULL)!=1) LIMIT 1
            """,bindings:binding) == nil else { throw CompletionReceiptError.invalidEvidence("Unclosed collision graph") }
        guard try database.scalar("""
            SELECT 1 FROM comparison_results WHERE comparison_id=? AND
              (difference_flags<0 OR difference_flags>31 OR
               (result_type='matched' AND (left_entry_id IS NULL OR right_entry_id IS NULL OR difference_flags!=0)) OR
               (result_type='changed' AND (left_entry_id IS NULL OR right_entry_id IS NULL OR difference_flags=0)) OR
               (result_type='added' AND (left_entry_id IS NOT NULL OR right_entry_id IS NULL OR difference_flags!=0)) OR
               (result_type='removed' AND (left_entry_id IS NULL OR right_entry_id IS NOT NULL OR difference_flags!=0)) OR
               (result_type='ignored' AND ((left_entry_id IS NULL)=(right_entry_id IS NULL) OR difference_flags!=0)) OR
               (result_type='uncertain' AND difference_flags!=0)) LIMIT 1
            """,bindings:binding) == nil else { throw CompletionReceiptError.invalidEvidence("Contradictory result shape") }
        var digest = SHA256()
        func frame(_ data: Data) {
            var size = UInt64(data.count).bigEndian
            withUnsafeBytes(of:&size) { digest.update(data:Data($0)) }; digest.update(data:data)
        }
        var totals: [String:Int64] = [:]
        func stream(table: String, columns: [String:String], predicate: String, bindings: [DatabaseValue]) throws -> Int64 {
            var cursor: Int64 = 0; var total: Int64 = 0
            while true {
                try checkpoint()
                let page = try metadataRows(table:table,columns:columns,predicate:"(\(predicate)) AND id>?",bindings:bindings+[.integer(cursor)],limit:256)
                if page.isEmpty { break }
                for row in page {
                    try CompletionEvidenceContract.validateRow(row,columns:columns,required:Set(columns.keys).subtracting(["parent_result_id","left_entry_id","right_entry_id"]))
                    guard let id = row["id"]?.integer, id > cursor else { throw CompletionReceiptError.invalidEvidence("Invalid evidence order") }
                    frame(try ComparisonCompletionReceipt.encoder().encode(row)); cursor = id; total += 1
                }
            }
            return total
        }
        for (table,columns) in [
            ("comparison_results",["id":"integer","comparison_id":"integer","parent_result_id":"integer","result_path":"text","display_name":"text","result_type":"text","left_entry_id":"integer","right_entry_id":"integer","difference_flags":"integer","created_at":"text"]),
            ("comparison_collision_groups",["id":"integer","comparison_id":"integer","result_path":"text","created_at":"text"])
        ] {
            frame(Data(table.utf8))
            totals[table] = try stream(table:table,columns:columns,predicate:"comparison_id=?",bindings:binding)
        }
        frame(Data("comparison_collision_members".utf8))
        var groupCursor: Int64 = 0; var memberCount: Int64 = 0
        while true {
            try checkpoint()
            let groups = try database.query("SELECT id FROM comparison_collision_groups WHERE comparison_id=? AND id>? ORDER BY id LIMIT 256",bindings:binding+[.integer(groupCursor)])
            if groups.isEmpty { break }
            for group in groups {
                guard let id = group["id"]?.int64Value, id > groupCursor else { throw CompletionReceiptError.invalidEvidence("Invalid group order") }
                memberCount += try stream(table:"comparison_collision_members",columns:["id":"integer","group_id":"integer","side":"text","entry_id":"integer","created_at":"text"],predicate:"group_id=?",bindings:[.integer(id)])
                groupCursor = id
            }
        }
        totals["comparison_collision_members"] = memberCount
        return CompletionResultClosure(counts:counts,resultRows:totals["comparison_results"]!,collisionGroups:totals["comparison_collision_groups"]!,collisionMembers:totals["comparison_collision_members"]!,
            leftEntries:try database.scalar("SELECT COUNT(*) FROM entries WHERE snapshot_id=?",bindings:[.integer(leftID)])!.int64Value!,
            rightEntries:try database.scalar("SELECT COUNT(*) FROM entries WHERE snapshot_id=?",bindings:[.integer(rightID)])!.int64Value!,metadataSHA256:digest.finalize().map { String(format:"%02x",$0) }.joined())
    }
}
