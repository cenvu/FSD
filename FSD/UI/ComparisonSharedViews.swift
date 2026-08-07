import SwiftUI

/// Shared empty-state presentation used by the comparison destination, the
/// creation view, the workspace view and the app shell. File-scope internal so
/// every UI file can use it without duplicating it per file.
struct EmptyStateView: View {
    let title: String
    let systemImage: String
    var detail: String?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage).font(.system(size: 36)).foregroundStyle(.secondary)
            Text(title).font(.title3)
            if let detail {
                Text(detail).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 420)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title + (detail.map { ", \($0)" } ?? ""))
    }
}

/// Bounded, user-facing descriptions for errors the comparison GUI surfaces.
/// The GUI never renders raw SQLite text when a bounded description exists.
enum ComparisonUIErrorDescription {
    static func message(for error: Error) -> String {
        if let comparisonError = error as? ComparisonError {
            switch comparisonError {
            case let .database(databaseError):
                return message(for: databaseError)
            case let .liveCaptureFailed(scannerError):
                return message(for: scannerError)
            case let .collisionGroupTooLarge(count):
                return "A single comparison identity has too many members (\(count)) to classify safely. No arbitrary pairing was performed."
            default:
                return comparisonError.errorDescription ?? "The comparison could not be completed."
            }
        }
        if let scannerError = error as? SnapshotScannerError {
            return message(for: scannerError)
        }
        if let databaseError = error as? CatalogDatabaseError {
            return message(for: databaseError)
        }
        if error is CancellationError {
            return "The comparison was cancelled."
        }
        return "An unexpected error occurred."
    }

    static func message(for error: SnapshotScannerError) -> String {
        switch error {
        case .captureFailed:
            // Fixed, bounded presentation. This case carries an arbitrary
            // underlying `localizedDescription` (raw SQLite, POSIX/Cocoa,
            // path or provider internals), so the carried string must never
            // reach the user. The user only needs to know the capture failed
            // and what they can do next.
            return "Metadata capture failed. Verify that the source is available and try again."
        default:
            // Provider, writer and detector conditions keep their own fixed
            // wording; nothing here interpolates underlying error text.
            return "The live source could not be captured as metadata."
        }
    }

    static func message(for error: CatalogDatabaseError) -> String {
        switch error {
        case .cannotOpen:
            return "The catalog could not be opened."
        case let .sqlite(code, _):
            // Bounded presentation: the raw SQLite message is suppressed.
            return "The catalog database reported an error (code \(code))."
        case .missingSchemaResource:
            return "The catalog schema resource is missing."
        case .unsupportedSchemaVersion:
            return "The catalog uses an unsupported schema version."
        case .foreignKeysNotEnabled:
            return "The catalog integrity guard is unavailable."
        case .invalidSchemaVersion:
            return "The catalog schema version is invalid."
        case .migrationFailed:
            return "The catalog could not be migrated."
        case .schemaStateInvalid:
            return "The catalog state is invalid."
        }
    }
}

/// Stable, textual outcome wording. Color is never the only status
/// indicator: every result row and summary pill carries these words, and
/// the canonical orientation (left = reference/before, right = changed/after)
/// is expressed in the wording for added/removed.
enum ComparisonOutcomeWording {
    static func label(for type: ComparisonResultType) -> String {
        switch type {
        case .matched: return "Matched"
        case .added: return "Added — found only on the right (changed) side"
        case .removed: return "Removed — found only on the left (reference) side"
        case .changed: return "Changed"
        case .uncertain: return "Uncertain — no deterministic conclusion"
        case .ignored: return "Ignored"
        }
    }

    static func shortLabel(for type: ComparisonResultType) -> String {
        switch type {
        case .matched: return "Matched"
        case .added: return "Added"
        case .removed: return "Removed"
        case .changed: return "Changed"
        case .uncertain: return "Uncertain"
        case .ignored: return "Ignored"
        }
    }
}
