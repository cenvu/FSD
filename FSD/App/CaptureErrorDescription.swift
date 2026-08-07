import Foundation

/// Bounded, user-facing descriptions for the legacy capture screen's failure
/// state (`CaptureState.failed`).
///
/// The visible capture UI never renders arbitrary diagnostic text. Scanner,
/// provider, SQLite, POSIX/Cocoa, filesystem and path messages stay internal —
/// still available for diagnostics through `diagnosticLine` (written to
/// standard error, the same channel the startup diagnostics use) — while the
/// screen shows fixed or safely typed wording.
///
/// This is the capture surface's own boundary, deliberately separate from the
/// comparison GUI's `ComparisonUIErrorDescription`: the same policy, applied
/// consistently, without coupling the capture UI to comparison models.
public enum CaptureErrorDescription {
    public static func message(for error: SnapshotScannerError) -> String {
        switch error {
        case .captureFailed:
            // Fixed, bounded presentation. This case carries an arbitrary
            // underlying `localizedDescription` (raw SQLite, POSIX/Cocoa,
            // path or provider internals), so the carried string must never
            // reach the user. The user only needs to know the capture failed
            // and what they can do next.
            return "Metadata capture failed. Verify that the source is available and try again."
        case .provider(.invalidSource), .provider(.outsideSelectedRoot):
            return "The selected source is not readable as a metadata source."
        case .provider(.metadataUnavailable):
            return "Metadata for the selected source could not be read."
        case .provider(.cancelled):
            return "The capture was cancelled."
        case .writer:
            return "The capture could not be recorded in the catalog."
        case .detector:
            return "The source type could not be identified."
        }
    }

    public static func message(for error: Error) -> String {
        if let scannerError = error as? SnapshotScannerError {
            return message(for: scannerError)
        }
        if error is CatalogDatabaseError {
            return "The catalog could not record the capture."
        }
        if error is CancellationError {
            return "The capture was cancelled."
        }
        return "The capture could not be completed."
    }

    /// The full diagnostic, kept internal: written to standard error so an
    /// operator or automated probe can diagnose a failed capture without the
    /// visible capture UI ever showing it.
    public static func diagnosticLine(for error: Error) -> String {
        "FSD capture failed: \(error.localizedDescription)"
    }
}
