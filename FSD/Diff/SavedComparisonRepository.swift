import Foundation
import CryptoKit

public enum SavedComparisonError: Error, Equatable {
    case ineligible
    case identityConflict
    case deleted
    case notFound
    case corrupt(String)
    case budgetExceeded(String)
    case cancelled
}

public struct SavedComparisonRequest: Sendable {
    public let operationID: UUID
    public let catalogGeneration: UUID
    public let completionToken: UUID
    public let comparisonID: ComparisonID
    public init(operationID: UUID, receipt: ComparisonCompletionReceipt) {
        self.operationID = operationID; catalogGeneration = receipt.catalogGeneration
        completionToken = receipt.completionToken; comparisonID = ComparisonID(rawValue: receipt.comparisonID)
    }
}

/// Caller may reduce these ceilings, never enlarge the production envelope.
/// Cooperative limits cover admission, validation, copy and precommit. They do
/// not claim an OS hard timeout, disk reservation or power-loss guarantee.
public struct SavedComparisonLimits: Sendable {
    public var rows: Int64 = 100_000
    public var metadataBytes: Int64 = 256 * 1024 * 1024
    public var databaseGrowthBytes: Int64 = 512 * 1024 * 1024
    public var elapsedSeconds: Double = 60
    public init() {}
}

public struct SavedEvidenceRow: Sendable, Equatable {
    public let id: Int64
    public let treeID: Int64?
    public let parentID: Int64?
    public let leftEntryID: Int64?
    public let rightEntryID: Int64?
    public let entryID: Int64?
    public let groupID: Int64?
    /// Exact typed original values, including original IDs as provenance only.
    /// All navigation references above belong to the dedicated saved graph.
    public let original: [String: CompletionMetadataValue]
}

public enum SavedComparisonSide: String, Sendable { case left, right }

/// Read-only handle, validated on open. Every page checks that the artifact
/// still exists and is READY; sealed evidence is immutable under v13 guards.
public final class SavedComparisonReader {
    public let id: UUID
    public let receipt: ComparisonCompletionReceipt
    private let repository: SavedComparisonRepository
    init(id: UUID, receipt: ComparisonCompletionReceipt, repository: SavedComparisonRepository) {
        self.id = id; self.receipt = receipt; self.repository = repository
    }
    public func entries(side: SavedComparisonSide, after: Int64 = 0, limit: Int = 256) throws -> [SavedEvidenceRow] {
        try repository.page(id: id, table: "saved_entries", side: side, after: after, limit: limit)
    }
    public func issues(side: SavedComparisonSide, after: Int64 = 0, limit: Int = 256) throws -> [SavedEvidenceRow] {
        try repository.page(id: id, table: "saved_issues", side: side, after: after, limit: limit)
    }
    public func results(after: Int64 = 0, limit: Int = 256) throws -> [SavedEvidenceRow] {
        try repository.page(id: id, table: "saved_results", side: nil, after: after, limit: limit)
    }
    public func collisionGroups(after: Int64 = 0, limit: Int = 256) throws -> [SavedEvidenceRow] {
        try repository.page(id: id, table: "saved_collision_groups", side: nil, after: after, limit: limit)
    }
    public func collisionMembers(after: Int64 = 0, limit: Int = 256) throws -> [SavedEvidenceRow] {
        try repository.page(id: id, table: "saved_collision_members", side: nil, after: after, limit: limit)
    }
}

/// Explicit backend action only. No initializer, completion path, reader or
/// workspace lifecycle invokes save. All reads/copies are catalog metadata.
public final class SavedComparisonRepository {
    public static let pageSize = 256
    private let database: CatalogDatabase
    // Internal failure/measurement seam; never changes transaction ownership.
    var checkpointObserver: ((String) throws -> Void)?
    public init(database: CatalogDatabase) { self.database = database }

    @discardableResult
    public func save(_ request: SavedComparisonRequest, limits: SavedComparisonLimits = .init(), isCancelled: @escaping () -> Bool = { false }) throws -> UUID {
        let budget = try Budget(database: database, limits: limits, cancelled: isCancelled)
        return try database.transaction {
            func check(_ stage: String) throws { try budget.check(); try checkpointObserver?(stage) }
            try check("admission")
            if let op = try database.query("SELECT * FROM saved_operations WHERE id=?", bindings: [.text(request.operationID.uuidString)]).first {
                guard op["catalog_generation"]?.stringValue == request.catalogGeneration.uuidString,
                      op["completion_token"]?.stringValue == request.completionToken.uuidString,
                      op["comparison_id"]?.int64Value == request.comparisonID.rawValue,
                      let id = op["artifact_id"]?.stringValue.flatMap(UUID.init(uuidString:)) else { throw SavedComparisonError.identityConflict }
                guard op["state"]?.stringValue == "ready" else { throw SavedComparisonError.deleted }
                _ = try validate(id: id, budget: budget)
                return id
            }
            for (table,columns) in [("entries",Self.entryColumns),("comparison_results",Self.resultColumns),("comparison_collision_groups",Self.groupColumns),("comparison_collision_members",Self.memberColumns)] {
                let actual = try database.query("SELECT name FROM pragma_table_info(?) LIMIT 128",bindings:[.text(table)]).compactMap { $0["name"]?.stringValue }
                guard Set(actual) == Set(columns.keys) else { throw SavedComparisonError.corrupt("unsupported source fields") }
            }
            // Reject oversized work before the trusted receipt's closure walk.
            guard let raw = try database.query("SELECT length(payload) bytes,left_snapshot_id l,right_snapshot_id r FROM comparison_completion_receipts WHERE comparison_id=?",bindings:[.integer(request.comparisonID.rawValue)]).first,
                  let l = raw["l"]?.int64Value, let r = raw["r"]?.int64Value else { throw SavedComparisonError.ineligible }
            let rowCount = try database.scalar("""
                SELECT (SELECT COUNT(*) FROM entries WHERE snapshot_id=?)+(SELECT COUNT(*) FROM entries WHERE snapshot_id=?)
                  +(SELECT COUNT(*) FROM comparison_results WHERE comparison_id=?)
                  +(SELECT COUNT(*) FROM comparison_collision_groups WHERE comparison_id=?)
                  +(SELECT COUNT(*) FROM comparison_collision_members m JOIN comparison_collision_groups g ON g.id=m.group_id WHERE g.comparison_id=?)
                """,bindings:[.integer(l),.integer(r),.integer(request.comparisonID.rawValue),.integer(request.comparisonID.rawValue),.integer(request.comparisonID.rawValue)])?.int64Value
            guard let rowCount, rowCount <= budget.maximumRows else { throw SavedComparisonError.budgetExceeded("rows") }
            guard let receipt = try ComparisonCompletionReceiptRepository(database: database).validatedReceipt(comparisonID: request.comparisonID, checkpoint: { try check("receipt") }) else { throw SavedComparisonError.ineligible }
            guard receipt.catalogGeneration == request.catalogGeneration, receipt.completionToken == request.completionToken,
                  receipt.comparisonID == request.comparisonID.rawValue else { throw SavedComparisonError.identityConflict }
            let data = try receipt.encoded()
            try budget.charge(rows: 1, bytes: data.count)
            let artifact = UUID(); let a: DatabaseValue = .text(artifact.uuidString)
            try database.execute("INSERT INTO saved_comparisons(id,state,format_version,receipt,created_at) VALUES (?,'building',1,?,CURRENT_TIMESTAMP)",bindings:[a,.blob(data)])
            try check("artifact")
            var trees: [String:Int64] = [:]
            for (side,evidence) in [("left",receipt.left),("right",receipt.right)] {
                let snapshot = evidence.header["id"]!.integer!
                try validateSourceTree(snapshot)
                try database.execute("INSERT INTO saved_trees(artifact_id,side,origin_snapshot_id) VALUES (?,?,?)",bindings:[a,.text(side),.integer(snapshot)])
                let tree = try database.lastInsertRowID(); trees[side] = tree
                try check(side+"_tree")
                try streamSource(table:"entries", columns:Self.entryColumns, predicate:"snapshot_id=?", bindings:[.integer(snapshot)], budget:budget) { row,data in
                    try database.execute("INSERT INTO saved_entries(artifact_id,tree_id,origin_id,payload) VALUES (?,?,?,?)",bindings:[a,.integer(tree),.integer(row["id"]!.integer!),.blob(data)])
                }
                // Second bounded pass handles any valid original ID ordering.
                try streamSaved(table:"saved_entries",artifact:artifact,budget:budget, tree:tree) { row,metadata in
                    let parent = try mapped("saved_entries", owner:"tree_id", value:.integer(tree), origin:metadata["parent_id"]!)
                    try database.execute("UPDATE saved_entries SET parent_id=? WHERE id=?",bindings:[parent,row["id"]!])
                }
                try check(side+"_entries")
                for issue in evidence.issues {
                    try check(side+"_issue_page")
                    let payload = try Self.encode(issue); try budget.charge(rows:1,bytes:payload.count)
                    let entry = try mapped("saved_entries",owner:"tree_id",value:.integer(tree),origin:issue["entry_id"]!)
                    try database.execute("INSERT INTO saved_issues(artifact_id,tree_id,origin_id,entry_id,payload) VALUES (?,?,?,?,?)",bindings:[a,.integer(tree),.integer(issue["id"]!.integer!),entry,.blob(payload)])
                }
                try check(side+"_issues")
            }
            let lt = DatabaseValue.integer(trees["left"]!), rt = DatabaseValue.integer(trees["right"]!)
            try streamSource(table:"comparison_results",columns:Self.resultColumns,predicate:"comparison_id=?",bindings:[.integer(receipt.comparisonID)],budget:budget) { row,data in
                let left = try mapped("saved_entries",owner:"tree_id",value:lt,origin:row["left_entry_id"]!)
                let right = try mapped("saved_entries",owner:"tree_id",value:rt,origin:row["right_entry_id"]!)
                try database.execute("INSERT INTO saved_results(artifact_id,origin_id,left_tree_id,right_tree_id,left_entry_id,right_entry_id,payload) VALUES (?,?,?,?,?,?,?)",bindings:[a,.integer(row["id"]!.integer!),lt,rt,left,right,.blob(data)])
            }
            try streamSaved(table:"saved_results",artifact:artifact,budget:budget) { row,metadata in
                let parent = try mapped("saved_results",owner:"artifact_id",value:a,origin:metadata["parent_result_id"]!)
                try database.execute("UPDATE saved_results SET parent_id=? WHERE id=?",bindings:[parent,row["id"]!])
            }
            try check("results")
            try streamSource(table:"comparison_collision_groups",columns:Self.groupColumns,predicate:"comparison_id=?",bindings:[.integer(receipt.comparisonID)],budget:budget) { row,data in
                try database.execute("INSERT INTO saved_collision_groups(artifact_id,origin_id,payload) VALUES (?,?,?)",bindings:[a,.integer(row["id"]!.integer!),.blob(data)])
            }
            try check("groups")
            // Group-ID then member-ID keysets use existing production indexes.
            var groupCursor: Int64 = 0
            while true {
                try check("member_group_page")
                let groups = try database.query("SELECT id FROM comparison_collision_groups WHERE comparison_id=? AND id>? ORDER BY id LIMIT 256",bindings:[.integer(receipt.comparisonID),.integer(groupCursor)])
                if groups.isEmpty { break }
                for groupRow in groups {
                    let originalGroup = groupRow["id"]!.int64Value!
                    try streamSource(table:"comparison_collision_members",columns:Self.memberColumns,predicate:"group_id=?",bindings:[.integer(originalGroup)],budget:budget) { row,data in
                        guard let side = row["side"]?.text, let tree = trees[side] else { throw SavedComparisonError.corrupt("member side") }
                        let group = try mapped("saved_collision_groups",owner:"artifact_id",value:a,origin:row["group_id"]!)
                        let entry = try mapped("saved_entries",owner:"tree_id",value:.integer(tree),origin:row["entry_id"]!)
                        try database.execute("INSERT INTO saved_collision_members(artifact_id,origin_id,group_id,side,tree_id,entry_id,payload) VALUES (?,?,?,?,?,?,?)",bindings:[a,.integer(row["id"]!.integer!),group,.text(side),.integer(tree),entry,.blob(data)])
                    }
                    groupCursor = originalGroup
                }
            }
            try check("members")
            for (side,evidence) in [("left",receipt.left),("right",receipt.right)] {
                let tree = trees[side]!
                try streamSource(table:"entries",columns:Self.entryColumns,predicate:"snapshot_id=?",bindings:[.integer(evidence.header["id"]!.integer!)],budget:budget,accountCopy:false) { row,encoded in
                    guard try database.scalar("SELECT payload FROM saved_entries WHERE tree_id=? AND origin_id=?",bindings:[.integer(tree),.integer(row["id"]!.integer!)]) == .blob(encoded) else { throw SavedComparisonError.corrupt("copied entry differs from original") }
                }
            }
            let digest = try validateGraph(id:artifact,receipt:receipt,budget:budget)
            try check("validated")
            try database.execute("UPDATE saved_comparisons SET state='ready',graph_sha256=? WHERE id=?",bindings:[.text(digest),a])
            try check("ready")
            try database.execute("INSERT INTO saved_operations(id,catalog_generation,completion_token,comparison_id,artifact_id,state) VALUES (?,?,?,?,?,'ready')",bindings:[.text(request.operationID.uuidString),.text(request.catalogGeneration.uuidString),.text(request.completionToken.uuidString),.integer(request.comparisonID.rawValue),a])
            try check("operation")
            try check("precommit")
            return artifact
        }
    }

    public func open(id: UUID, limits: SavedComparisonLimits = .init()) throws -> SavedComparisonReader {
        let budget = try Budget(database:database,limits:limits,cancelled:{ false })
        let receipt = try database.transaction { try validate(id:id,budget:budget) }
        return SavedComparisonReader(id:id,receipt:receipt,repository:self)
    }
    /// Small bounded list; opening verifies all evidence before browsing.
    public func list(after: String = "", limit: Int = 100) throws -> [UUID] {
        try database.query("SELECT id FROM saved_comparisons WHERE state='ready' AND id>? ORDER BY id LIMIT ?",bindings:[.text(after),.integer(Int64(max(1,min(256,limit))))]).map {
            guard let id = $0["id"]?.stringValue.flatMap(UUID.init(uuidString:)) else { throw SavedComparisonError.corrupt("artifact ID") }; return id
        }
    }
    /// Entire owned graph removed in one transaction. Permanent operation row
    /// changes to deleted before cascade; retry can never rebuild this artifact.
    public func delete(id: UUID) throws {
        try database.transaction {
            let found = try database.scalar("SELECT state FROM saved_comparisons WHERE id=?",bindings:[.text(id.uuidString)])
            if found == nil {
                guard try database.scalar("SELECT 1 FROM saved_operations WHERE artifact_id=? AND state='deleted'",bindings:[.text(id.uuidString)]) != nil else { throw SavedComparisonError.notFound }
                return
            }
            try database.execute("DELETE FROM saved_comparisons WHERE id=?",bindings:[.text(id.uuidString)])
        }
    }

    private func validate(id: UUID, budget: Budget) throws -> ComparisonCompletionReceipt {
        try budget.check()
        guard try database.scalar("SELECT 1 FROM saved_comparisons WHERE id=? AND (typeof(receipt)!='blob' OR length(receipt)>8388608 OR length(receipt)=0)",bindings:[.text(id.uuidString)]) == nil else { throw SavedComparisonError.corrupt("oversized receipt") }
        guard let row = try database.query("SELECT * FROM saved_comparisons WHERE id=? AND state='ready'",bindings:[.text(id.uuidString)]).first else { throw SavedComparisonError.notFound }
        guard row["format_version"]?.int64Value == 1, case .blob(let bytes) = row["receipt"], let seal = row["graph_sha256"]?.stringValue else { throw SavedComparisonError.corrupt("artifact header") }
        let receipt: ComparisonCompletionReceipt
        do { receipt = try ComparisonCompletionReceipt.decode(bytes) }
        catch { throw SavedComparisonError.corrupt("invalid archived receipt") }
        guard let op = try database.query("SELECT * FROM saved_operations WHERE artifact_id=? AND state='ready'",bindings:[.text(id.uuidString)]).first,
              op["catalog_generation"]?.stringValue == receipt.catalogGeneration.uuidString,
              op["completion_token"]?.stringValue == receipt.completionToken.uuidString,
              op["comparison_id"]?.int64Value == receipt.comparisonID else { throw SavedComparisonError.corrupt("operation receipt") }
        try budget.charge(rows:1,bytes:bytes.count)
        guard try validateGraph(id:id,receipt:receipt,budget:budget) == seal else { throw SavedComparisonError.corrupt("evidence seal") }
        return receipt
    }

    private func validateSourceTree(_ snapshot: Int64) throws {
        let b: [DatabaseValue] = [.integer(snapshot)]
        guard try database.scalar("SELECT 1 FROM snapshots WHERE id=? AND status IN ('complete','complete_with_warnings')",bindings:b) != nil,
              try database.scalar("SELECT COUNT(*) FROM entries WHERE snapshot_id=? AND parent_id IS NULL AND relative_path=''",bindings:b)?.int64Value == 1,
              try database.scalar("""
                SELECT 1 FROM entries e LEFT JOIN entries p ON p.id=e.parent_id AND p.snapshot_id=e.snapshot_id
                WHERE e.snapshot_id=? AND e.parent_id IS NOT NULL AND
                  (p.id IS NULL OR p.item_type NOT IN ('directory','package') OR
                   e.relative_path != CASE WHEN p.relative_path='' THEN e.name ELSE p.relative_path||'/'||e.name END) LIMIT 1
                """,bindings:b) == nil else { throw SavedComparisonError.corrupt("unsealed source tree") }
    }

    private func mapped(_ table: String, owner: String, value: DatabaseValue, origin: CompletionMetadataValue) throws -> DatabaseValue {
        if origin == .null { return .null }
        guard let id = origin.integer, let result = try database.scalar("SELECT id FROM \(table) WHERE \(owner)=? AND origin_id=?",bindings:[value,.integer(id)]) else { throw SavedComparisonError.corrupt("missing ID mapping") }
        return result
    }

    private static func encode(_ row: [String:CompletionMetadataValue]) throws -> Data {
        let data = try ComparisonCompletionReceipt.encoder().encode(row)
        guard data.count <= 524288 else { throw SavedComparisonError.budgetExceeded("row encoding") }
        return data
    }
    private static func decode(_ data: Data, columns: [String:String]) throws -> [String:CompletionMetadataValue] {
        guard data.count <= 524288 else { throw SavedComparisonError.corrupt("oversized row") }
        do {
            let row = try JSONDecoder().decode([String:CompletionMetadataValue].self,from:data)
            try CompletionEvidenceContract.validateRow(row,columns:columns,required:[])
            guard try encode(row) == data else { throw SavedComparisonError.corrupt("noncanonical metadata") }
            return row
        } catch { throw SavedComparisonError.corrupt("invalid saved metadata") }
    }

    /// Preflight sizes and exact SQLite types BEFORE materializing each page.
    /// TEXT hex parity rejects invalid UTF8/NUL instead of C-string truncation.
    private func streamSource(table: String, columns: [String:String], predicate: String, bindings: [DatabaseValue], budget: Budget, accountCopy: Bool = true, body: ([String:CompletionMetadataValue],Data) throws -> Void) throws {
        let names = columns.keys.sorted()
        let bytes = names.map { "coalesce(length(CAST(\($0) AS BLOB)),0)" }.joined(separator:"+")
        let bad = names.map { "(typeof(\($0)) NOT IN ('null','\(columns[$0]!)') OR length(CAST(\($0) AS BLOB))>65536)" }.joined(separator:" OR ")
        let projection = names.flatMap { columns[$0] == "text" ? [$0,"hex(CAST(\($0) AS BLOB)) raw_\($0)"] : [$0] }.joined(separator:",")
        var cursor: Int64 = 0
        while true {
            try budget.check()
            let clause = "\(predicate) AND id>? ORDER BY id LIMIT 256"
            let b = bindings+[.integer(cursor)]
            guard try database.scalar("SELECT 1 FROM (SELECT * FROM \(table) WHERE \(clause)) WHERE \(bad) OR (\(bytes))>262144 LIMIT 1",bindings:b) == nil,
                  (try database.scalar("SELECT coalesce(sum(\(bytes)),0) FROM (SELECT * FROM \(table) WHERE \(clause))",bindings:b)?.int64Value ?? Int64.max) <= 4*1024*1024 else { throw SavedComparisonError.budgetExceeded("metadata page") }
            let page = try database.query("SELECT \(projection) FROM \(table) WHERE \(clause)",bindings:b)
            if page.isEmpty { break }
            for raw in page {
                var row: [String:CompletionMetadataValue] = [:]
                for name in names {
                    guard let value = raw[name] else { throw SavedComparisonError.corrupt("missing column") }
                    if case .text(let text) = value {
                        guard raw["raw_"+name]?.stringValue == CompletionEvidenceContract.hexUTF8(text), !text.contains("\0") else { throw SavedComparisonError.corrupt("invalid text") }
                    }
                    row[name] = try CompletionMetadataValue(value)
                }
                let data = try Self.encode(row); if accountCopy { try budget.charge(rows:1,bytes:data.count) }
                try body(row,data)
                guard let id = row["id"]?.integer, id>cursor else { throw SavedComparisonError.corrupt("row order") }; cursor=id
            }
        }
    }

    private static let evidenceTables = ["saved_entries","saved_issues","saved_results","saved_collision_groups","saved_collision_members"]
    private static func columns(_ table: String) -> [String:String] {
        switch table {
        case "saved_entries": return entryColumns
        case "saved_issues": return CompletionEvidenceContract.issueColumns
        case "saved_results": return resultColumns
        case "saved_collision_groups": return groupColumns
        default: return memberColumns
        }
    }
    private func savedPage(table: String, artifact: UUID, tree: Int64? = nil, after: Int64, limit: Int) throws -> [DatabaseRow] {
        let clause = "artifact_id=?"+(tree == nil ? "" : " AND tree_id=?")+" AND id>? ORDER BY id LIMIT ?"
        let b: [DatabaseValue] = [.text(artifact.uuidString)]+(tree.map { [.integer($0)] } ?? [])+[.integer(after),.integer(Int64(limit))]
        guard (try database.scalar("SELECT coalesce(sum(length(payload)),0) FROM (SELECT payload FROM \(table) WHERE \(clause))",bindings:b)?.int64Value ?? Int64.max) <= 8*1024*1024 else { throw SavedComparisonError.budgetExceeded("saved page") }
        return try database.query("SELECT * FROM \(table) WHERE \(clause)",bindings:b)
    }
    private func streamSaved(table: String, artifact: UUID, budget: Budget, tree: Int64? = nil, body: (DatabaseRow,[String:CompletionMetadataValue]) throws -> Void) throws {
        var cursor: Int64 = 0
        while true {
            try budget.check()
            let page = try savedPage(table:table,artifact:artifact,tree:tree,after:cursor,limit:256)
            if page.isEmpty { break }
            for row in page {
                guard let id = row["id"]?.int64Value, id>cursor, case .blob(let data) = row["payload"] else { throw SavedComparisonError.corrupt("saved row") }
                try body(row,Self.decode(data,columns:Self.columns(table))); cursor=id
            }
        }
    }

    private func validateGraph(id: UUID, receipt: ComparisonCompletionReceipt, budget: Budget) throws -> String {
        let a: [DatabaseValue] = [.text(id.uuidString)]
        let trees = try database.query("SELECT * FROM saved_trees WHERE artifact_id=? ORDER BY side",bindings:a)
        guard trees.count == 2, trees[0]["side"]?.stringValue == "left", trees[1]["side"]?.stringValue == "right",
              trees[0]["origin_snapshot_id"]?.int64Value == receipt.left.header["id"]?.integer,
              trees[1]["origin_snapshot_id"]?.int64Value == receipt.right.header["id"]?.integer else { throw SavedComparisonError.corrupt("side ownership") }
        let left = trees[0]["id"]!, right = trees[1]["id"]!
        var digest = SHA256()
        func frame(_ data: Data) { var size = UInt64(data.count).bigEndian; withUnsafeBytes(of:&size) { digest.update(data:Data($0)) }; digest.update(data:data) }
        guard let header = try database.query("SELECT id,format_version,created_at FROM saved_comparisons WHERE id=?",bindings:a).first else { throw SavedComparisonError.corrupt("missing artifact") }
        frame(try Self.encode(header.mapValues { try CompletionMetadataValue($0) }))
        frame(try receipt.encoded())
        for tree in trees { frame(try Self.encode(tree.mapValues { try CompletionMetadataValue($0) })) }
        var counts: [String:Int64] = [:]
        var resultCounts = Dictionary(uniqueKeysWithValues:ComparisonResultType.allCases.map { ($0.rawValue,Int64(0)) })
        var originalDigest = SHA256()
        func originalFrame(_ data: Data) { var size=UInt64(data.count).bigEndian; withUnsafeBytes(of:&size) { originalDigest.update(data:Data($0)) }; originalDigest.update(data:data) }
        var entryCounts: [Int64:Int64] = [:]; var issueCounts: [Int64:Int] = [:]
        var visited: Int64 = 1; var metadataBytes = Int64(try receipt.encoded().count)
        for table in Self.evidenceTables {
            frame(Data(table.utf8)); var count: Int64 = 0
            if ["saved_results","saved_collision_groups"].contains(table) { originalFrame(Data((table == "saved_results" ? "comparison_results" : "comparison_collision_groups").utf8)) }
            try streamSaved(table:table,artifact:id,budget:budget) { row,metadata in
                guard row["origin_id"]?.int64Value == metadata["id"]?.integer else { throw SavedComparisonError.corrupt("origin mapping") }
                count += 1; visited += 1
                guard case .blob(let storedPayload) = row["payload"] else { throw SavedComparisonError.corrupt("payload") }
                metadataBytes += Int64(storedPayload.count)
                try budget.validateSize(rows:visited,bytes:metadataBytes)
                // Hash the actual remapped fields AND exact typed original payload.
                frame(try Self.encode(row.mapValues { try CompletionMetadataValue($0) }))
                switch table {
                case "saved_entries", "saved_issues":
                    guard let tree = row["tree_id"]?.int64Value, tree == left.int64Value || tree == right.int64Value else { throw SavedComparisonError.corrupt("foreign tree") }
                    let evidence = tree == left.int64Value ? receipt.left : receipt.right
                    guard metadata["snapshot_id"] == evidence.header["id"] else { throw SavedComparisonError.corrupt("snapshot provenance") }
                    if table == "saved_entries" {
                        entryCounts[tree,default:0] += 1
                        try validateMapped(row["parent_id"]!, table:"saved_entries",owner:"tree_id",value:.integer(tree),origin:metadata["parent_id"]!)
                        guard metadata["relative_path"]?.text.map(PathIdentity.casePreserving) == metadata["case_preserving_path"]?.text,
                              metadata["relative_path"]?.text.map(PathIdentity.caseFold) == metadata["case_folded_path"]?.text,
                              metadata["name"]?.text.map(PathIdentity.casePreserving) == metadata["case_preserving_name"]?.text,
                              metadata["name"]?.text.map(PathIdentity.caseFold) == metadata["case_folded_name"]?.text else { throw SavedComparisonError.corrupt("normalized paths") }
                    } else {
                        let index = issueCounts[tree,default:0]
                        guard index < evidence.issues.count, evidence.issues[index] == metadata else { throw SavedComparisonError.corrupt("frozen issues") }
                        issueCounts[tree] = index+1
                        try validateMapped(row["entry_id"]!,table:"saved_entries",owner:"tree_id",value:.integer(tree),origin:metadata["entry_id"]!)
                    }
                case "saved_results":
                    guard metadata["comparison_id"]?.integer == receipt.comparisonID, row["left_tree_id"] == left, row["right_tree_id"] == right,
                          let kind = metadata["result_type"]?.text, resultCounts[kind] != nil else { throw SavedComparisonError.corrupt("result identity") }
                    resultCounts[kind]! += 1
                    try validateMapped(row["parent_id"]!,table:"saved_results",owner:"artifact_id",value:a[0],origin:metadata["parent_result_id"]!)
                    try validateMapped(row["left_entry_id"]!,table:"saved_entries",owner:"tree_id",value:left,origin:metadata["left_entry_id"]!)
                    try validateMapped(row["right_entry_id"]!,table:"saved_entries",owner:"tree_id",value:right,origin:metadata["right_entry_id"]!)
                    originalFrame(try Self.encode(metadata))
                case "saved_collision_groups":
                    guard metadata["comparison_id"]?.integer == receipt.comparisonID else { throw SavedComparisonError.corrupt("group identity") }
                    originalFrame(try Self.encode(metadata))
                default:
                    guard row["side"]?.stringValue == metadata["side"]?.text, let side = row["side"]?.stringValue,
                          row["tree_id"] == (side == "left" ? left : right) else { throw SavedComparisonError.corrupt("collision side") }
                    try validateMapped(row["group_id"]!,table:"saved_collision_groups",owner:"artifact_id",value:a[0],origin:metadata["group_id"]!)
                    try validateMapped(row["entry_id"]!,table:"saved_entries",owner:"tree_id",value:row["tree_id"]!,origin:metadata["entry_id"]!)
                }
            }
            counts[table]=count
        }
        // Receipt member digest order is original group ID then member ID.
        originalFrame(Data("comparison_collision_members".utf8))
        var groupCursor: Int64 = 0
        while true {
            try budget.check()
            let groups = try database.query("SELECT id,origin_id FROM saved_collision_groups WHERE artifact_id=? AND origin_id>? ORDER BY origin_id LIMIT 256",bindings:a+[.integer(groupCursor)])
            if groups.isEmpty { break }
            for group in groups {
                var cursor: Int64 = 0
                while true {
                    try budget.check()
                    let memberBindings = [group["id"]!,DatabaseValue.integer(cursor)]
                    guard (try database.scalar("SELECT coalesce(sum(length(payload)),0) FROM (SELECT payload FROM saved_collision_members WHERE group_id=? AND origin_id>? ORDER BY origin_id LIMIT 256)",bindings:memberBindings)?.int64Value ?? Int64.max) <= 8*1024*1024 else { throw SavedComparisonError.budgetExceeded("member page") }
                    let page = try database.query("SELECT origin_id,payload FROM saved_collision_members WHERE group_id=? AND origin_id>? ORDER BY origin_id LIMIT 256",bindings:memberBindings)
                    if page.isEmpty { break }
                    for member in page {
                        guard case .blob(let data) = member["payload"], let origin = member["origin_id"]?.int64Value else { throw SavedComparisonError.corrupt("member payload") }
                        originalFrame(data); cursor=origin
                    }
                }
                groupCursor=group["origin_id"]!.int64Value!
            }
        }
        guard counts["saved_results"] == receipt.closure.resultRows, counts["saved_collision_groups"] == receipt.closure.collisionGroups,
              counts["saved_collision_members"] == receipt.closure.collisionMembers, resultCounts == receipt.closure.counts,
              entryCounts[left.int64Value!] == receipt.closure.leftEntries, entryCounts[right.int64Value!] == receipt.closure.rightEntries,
              issueCounts[left.int64Value!,default:0] == receipt.left.issues.count, issueCounts[right.int64Value!,default:0] == receipt.right.issues.count,
              Self.hex(originalDigest.finalize()) == receipt.closure.metadataSHA256 else { throw SavedComparisonError.corrupt("receipt graph closure") }
        try budget.check()
        return Self.hex(digest.finalize())
    }
    private static func hex(_ digest: SHA256.Digest) -> String { digest.map { String(format:"%02x",$0) }.joined() }
    private func validateMapped(_ local: DatabaseValue, table: String, owner: String, value: DatabaseValue, origin: CompletionMetadataValue) throws {
        guard try mapped(table,owner:owner,value:value,origin:origin) == local else { throw SavedComparisonError.corrupt("remapped reference") }
    }
    fileprivate func page(id: UUID, table: String, side: SavedComparisonSide?, after: Int64, limit: Int) throws -> [SavedEvidenceRow] {
        try database.transaction {
            guard try database.scalar("SELECT 1 FROM saved_comparisons WHERE id=? AND state='ready'",bindings:[.text(id.uuidString)]) != nil else { throw SavedComparisonError.notFound }
            var tree: Int64?
            if let side {
                guard let found = try database.scalar("SELECT id FROM saved_trees WHERE artifact_id=? AND side=?",bindings:[.text(id.uuidString),.text(side.rawValue)])?.int64Value else { throw SavedComparisonError.corrupt("missing side") }; tree=found
            }
            return try savedPage(table:table,artifact:id,tree:tree,after:max(0,after),limit:max(1,min(256,limit))).map { row in
                guard case .blob(let data) = row["payload"], let local = row["id"]?.int64Value else { throw SavedComparisonError.corrupt("page row") }
                return SavedEvidenceRow(id:local,treeID:row["tree_id"]?.int64Value,parentID:row["parent_id"]?.int64Value,leftEntryID:row["left_entry_id"]?.int64Value,rightEntryID:row["right_entry_id"]?.int64Value,entryID:row["entry_id"]?.int64Value,groupID:row["group_id"]?.int64Value,original:try Self.decode(data,columns:Self.columns(table)))
            }
        }
    }

    private final class Budget {
        let database: CatalogDatabase
        let maximumRows: Int64
        private let maximumBytes: Int64
        private let maximumGrowth: Int64
        private let maximumElapsed: Double
        private let cancelled: () -> Bool
        private let started = ProcessInfo.processInfo.systemUptime
        private let initialPages: Int64
        private let pageBytes: Int64
        private var rows: Int64 = 0
        private var bytes: Int64 = 0
        init(database: CatalogDatabase, limits: SavedComparisonLimits, cancelled: @escaping () -> Bool) throws {
            self.database=database; self.cancelled=cancelled
            maximumRows=max(0,min(100_000,limits.rows)); maximumBytes=max(0,min(256*1024*1024,limits.metadataBytes))
            maximumGrowth=max(0,min(512*1024*1024,limits.databaseGrowthBytes)); maximumElapsed=limits.elapsedSeconds.isFinite ? max(0,min(60,limits.elapsedSeconds)) : 0
            initialPages=try database.scalar("PRAGMA page_count")?.int64Value ?? 0
            pageBytes=try database.scalar("PRAGMA page_size")?.int64Value ?? 4096
        }
        func check() throws {
            if cancelled() { throw SavedComparisonError.cancelled }
            guard ProcessInfo.processInfo.systemUptime-started < maximumElapsed else { throw SavedComparisonError.budgetExceeded("elapsed") }
            let pages=try database.scalar("PRAGMA page_count")?.int64Value ?? initialPages
            guard max(0,pages-initialPages) <= maximumGrowth/pageBytes else { throw SavedComparisonError.budgetExceeded("database growth") }
        }
        func validateSize(rows: Int64, bytes: Int64) throws {
            guard rows<=maximumRows else { throw SavedComparisonError.budgetExceeded("rows") }
            guard bytes<=maximumBytes else { throw SavedComparisonError.budgetExceeded("metadata bytes") }
        }
        func charge(rows count: Int64, bytes size: Int) throws {
            rows += count; bytes += Int64(size)
            try validateSize(rows:rows,bytes:bytes)
        }
    }

    static let resultColumns: [String:String] = ["id":"integer","comparison_id":"integer","parent_result_id":"integer","result_path":"text","display_name":"text","result_type":"text","left_entry_id":"integer","right_entry_id":"integer","difference_flags":"integer","created_at":"text"]
    static let groupColumns: [String:String] = ["id":"integer","comparison_id":"integer","result_path":"text","created_at":"text"]
    static let memberColumns: [String:String] = ["id":"integer","group_id":"integer","side":"text","entry_id":"integer","created_at":"text"]
    static let entryColumns: [String:String] = [
        "id":"integer","snapshot_id":"integer","parent_id":"integer","relative_path":"text","case_preserving_path":"text","case_folded_path":"text","name":"text","case_preserving_name":"text","case_folded_name":"text","file_extension":"text","item_type":"text","logical_size_bytes":"integer","allocated_size_bytes":"integer","created_at_source":"text","modified_at_source":"text","content_type_identifier":"text","resource_identifier":"blob","symlink_target":"text","is_hidden":"integer","is_package":"integer","is_inaccessible":"integer","direct_file_count":"integer","direct_folder_count":"integer","subtree_file_count":"integer","subtree_folder_count":"integer","subtree_logical_bytes":"integer","subtree_allocated_bytes":"integer","metadata_signature":"blob","subtree_signature":"blob","sort_key":"text","created_at":"text"
    ]
}
