import Foundation

/// Lifecycle of comparison scaffolding: transient snapshots (ADR-012) and the
/// comparison rows that reference them.
///
/// Explicit policies, all tested:
///
/// * **Orphaned comparisons** — a `running` comparison found at launch was
///   abandoned by a crashed process. It is terminalized as `failed` with the
///   counts of whatever was persisted; it is never presented as complete, and
///   its rows are never silently deleted. The comparison row is the safe
///   evidence of the abandoned work.
/// * **Unreferenced transients** — a transient snapshot not referenced by any
///   comparison row is scaffolding with no owner and is deleted
///   (entries/scan issues cascade). This runs at launch and after workspace
///   close, which is what makes an abandoned mid-capture transient disappear.
/// * **Referenced transients** — a transient referenced by a comparison row
///   is retained; the schema's `ON DELETE RESTRICT` forbids deleting it. The
///   comparison must be deleted first (the explicit disposal API), which is
///   exactly what workspace close does for live-side comparisons.
public final class TransientSnapshotLifecycle {
    private let database: CatalogDatabase

    public init(database: CatalogDatabase) {
        self.database = database
    }

    public struct ComparisonRecoveryReport: Sendable, Equatable {
        public let recoveredComparisonIDs: [ComparisonID]
        public let message: String?

        public init(recoveredComparisonIDs: [ComparisonID], message: String?) {
            self.recoveredComparisonIDs = recoveredComparisonIDs
            self.message = message
        }
    }

    /// Marks every `running` comparison as `failed`, recomputing its summary
    /// counts from the results actually persisted so the record stays
    /// internally consistent. Safe to run at every launch: a comparison can
    /// only be running inside this process, and the process lock guarantees
    /// no other process owns the catalog (ADR-025).
    public func recoverOrphanedComparisons() throws -> ComparisonRecoveryReport {
        let rows = try database.query("SELECT id FROM comparisons WHERE status = 'running' ORDER BY id")
        var recovered: [ComparisonID] = []
        for row in rows {
            guard let rawID = row["id"]?.int64Value else { continue }
            let id = ComparisonID(rawValue: rawID)
            try database.transaction {
                let stillRunning = try database.scalar(
                    "SELECT 1 FROM comparisons WHERE id = ? AND status = 'running' LIMIT 1",
                    bindings: [.integer(rawID)]
                )?.int64Value == 1
                guard stillRunning else { return }
                let counts = try database.query(
                    "SELECT result_type, COUNT(*) AS count FROM comparison_results WHERE comparison_id = ? GROUP BY result_type",
                    bindings: [.integer(rawID)]
                )
                var byType: [ComparisonResultType: Int64] = [:]
                for countRow in counts {
                    guard let raw = countRow["result_type"]?.stringValue, let type = ComparisonResultType(rawValue: raw) else { continue }
                    byType[type] = countRow["count"]?.int64Value ?? 0
                }
                try database.execute(
                    """
                    UPDATE comparisons SET
                        status = 'failed', completed_at = CURRENT_TIMESTAMP,
                        matched_count = ?, added_count = ?, removed_count = ?,
                        changed_count = ?, uncertain_count = ?
                    WHERE id = ? AND status = 'running'
                    """,
                    bindings: [
                        .integer(byType[.matched] ?? 0), .integer(byType[.added] ?? 0),
                        .integer(byType[.removed] ?? 0), .integer(byType[.changed] ?? 0),
                        .integer(byType[.uncertain] ?? 0), .integer(rawID)
                    ]
                )
                recovered.append(id)
            }
        }
        return ComparisonRecoveryReport(
            recoveredComparisonIDs: recovered,
            message: recovered.isEmpty ? nil : "Marked \(recovered.count) abandoned comparison(s) as failed."
        )
    }

    /// Deletes transient snapshots that no comparison references. Returns the
    /// number deleted. Never touches user snapshots and never touches a
    /// transient referenced by any comparison row.
    @discardableResult
    public func cleanupUnreferencedTransients() throws -> Int {
        let result = try database.transaction { () -> Int in
            let deleted = try database.executeWithRowCount(
                """
                DELETE FROM snapshots
                WHERE snapshot_kind = 'transient'
                  AND id NOT IN (
                      SELECT left_snapshot_id FROM comparisons WHERE left_snapshot_id IS NOT NULL
                      UNION
                      SELECT right_snapshot_id FROM comparisons WHERE right_snapshot_id IS NOT NULL
                  )
                """
            )
            return deleted
        }
        return result
    }

    /// Deletes one transient snapshot. Refuses when it is referenced by a
    /// comparison row (the schema's `ON DELETE RESTRICT` would reject it
    /// anyway; the comparison must be disposed first). Used by the
    /// comparison service to remove a failed live capture's residue.
    @discardableResult
    public func deleteTransient(_ id: SnapshotID) throws -> Bool {
        try database.transaction { () -> Bool in
            let referenced = try database.scalar(
                """
                SELECT 1 FROM comparisons
                WHERE left_snapshot_id = ? OR right_snapshot_id = ?
                LIMIT 1
                """,
                bindings: [.integer(id.rawValue), .integer(id.rawValue)]
            )?.int64Value == 1
            guard !referenced else { return false }
            try database.execute(
                "DELETE FROM snapshots WHERE id = ? AND snapshot_kind = 'transient'",
                bindings: [.integer(id.rawValue)]
            )
            return true
        }
    }

    /// Workspace close (ADR-012): terminalize disposable comparison state
    /// first — any running comparison whose sides include a transient is
    /// cancelled — then delete every live-side comparison (the disposal API),
    /// then delete the transient snapshots that just became unreferenced.
    ///
    /// Snapshot-to-snapshot comparisons are never touched: they are ordinary
    /// catalog history, not disposable workspace state.
    public func closeWorkspace() throws {
        try database.transaction {
            try database.execute(
                """
                UPDATE comparisons SET
                    status = 'cancelled', completed_at = CURRENT_TIMESTAMP,
                    matched_count = (SELECT COUNT(*) FROM comparison_results WHERE comparison_id = comparisons.id AND result_type = 'matched'),
                    added_count = (SELECT COUNT(*) FROM comparison_results WHERE comparison_id = comparisons.id AND result_type = 'added'),
                    removed_count = (SELECT COUNT(*) FROM comparison_results WHERE comparison_id = comparisons.id AND result_type = 'removed'),
                    changed_count = (SELECT COUNT(*) FROM comparison_results WHERE comparison_id = comparisons.id AND result_type = 'changed'),
                    uncertain_count = (SELECT COUNT(*) FROM comparison_results WHERE comparison_id = comparisons.id AND result_type = 'uncertain')
                WHERE status = 'running' AND id IN (
                    SELECT c.id FROM comparisons c
                    JOIN snapshots l ON c.left_snapshot_id = l.id
                    JOIN snapshots r ON c.right_snapshot_id = r.id
                    WHERE l.snapshot_kind = 'transient' OR r.snapshot_kind = 'transient'
                )
                """
            )
            try database.execute(
                """
                DELETE FROM comparisons WHERE id IN (
                    SELECT c.id FROM comparisons c
                    JOIN snapshots l ON c.left_snapshot_id = l.id
                    JOIN snapshots r ON c.right_snapshot_id = r.id
                    WHERE l.snapshot_kind = 'transient' OR r.snapshot_kind = 'transient'
                )
                """
            )
        }
        try cleanupUnreferencedTransients()
    }
}
