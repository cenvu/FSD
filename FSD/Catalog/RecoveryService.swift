import Foundation

public struct RecoveryReport: Sendable, Equatable {
    public let recoveredSnapshotIDs: [SnapshotID]
    public let message: String?

    public init(recoveredSnapshotIDs: [SnapshotID], message: String?) {
        self.recoveredSnapshotIDs = recoveredSnapshotIDs
        self.message = message
    }
}

public final class RecoveryService {
    public static let recoveryMessage = "Capture was interrupted when the application stopped before completion."
    private let database: CatalogDatabase

    public init(database: CatalogDatabase) {
        self.database = database
    }

    public func recoverOrphanedScans() throws -> RecoveryReport {
        let rows = try database.query("SELECT id FROM snapshots WHERE status = 'scanning' ORDER BY id")
        var recovered: [SnapshotID] = []
        for row in rows {
            guard let rawID = row["id"]?.int64Value else { continue }
            let id = SnapshotID(rawValue: rawID)
            try database.transaction {
                let status = try database.scalar(
                    "SELECT status FROM snapshots WHERE id = ?", bindings: [.integer(rawID)]
                )?.stringValue
                guard status == SnapshotStatus.scanning.rawValue else { return }
                let issueExists = try database.scalar(
                    "SELECT 1 FROM scan_issues WHERE snapshot_id = ? AND message = ? LIMIT 1",
                    bindings: [.integer(rawID), .text(Self.recoveryMessage)]
                )?.int64Value == 1
                if !issueExists {
                    try database.execute(
                        """
                        INSERT INTO scan_issues (snapshot_id, relative_path, severity, source, message, was_skipped, created_at)
                        VALUES (?, '', 'warning', 'scanner', ?, 1, CURRENT_TIMESTAMP)
                        """,
                        bindings: [.integer(rawID), .text(Self.recoveryMessage)]
                    )
                }
                try database.execute(
                    "UPDATE snapshots SET status = 'interrupted', warning_count = (SELECT COUNT(*) FROM scan_issues WHERE snapshot_id = ? AND severity IN ('warning', 'error')), completed_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP WHERE id = ? AND status = 'scanning'",
                    bindings: [.integer(rawID), .integer(rawID)]
                )
                recovered.append(id)
            }
        }
        return RecoveryReport(
            recoveredSnapshotIDs: recovered,
            message: recovered.isEmpty ? nil : "Recovered \(recovered.count) incomplete capture(s) as interrupted."
        )
    }
}
