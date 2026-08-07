import XCTest
@testable import FSD

/// KI-022 adversarial regression: the legacy capture screen must never display
/// arbitrary `error.localizedDescription` for scanner, provider, SQLite,
/// POSIX/Cocoa, filesystem, path or implementation errors. The visible
/// capture UI shows fixed or safely typed text through
/// `CaptureErrorDescription`; raw diagnostics remain internal (standard
/// error), and cancellation / unavailable-source / catalog failure stay
/// distinct.
final class CaptureErrorBoundaryTests: XCTestCase {
    private let hostileSQLite = "SQLITE_CORRUPT: database disk image is malformed at /Users/secret/.fsd/catalog.sqlite3 (1)"
    private let hostilePOSIX = "POSIX error: Operation not permitted (errno 1) at /private/var/fsd/provider/internal/token"
    private let hostileProvider = "provider-detail: unsupported metadata layout near block 0x7f00 (internal reader state)"

    // MARK: - Hostile arbitrary strings are never visible

    func testCaptureFailureArbitraryTextIsNeverVisible() {
        let sqliteError = SnapshotScannerError.captureFailed(hostileSQLite)
        let posixError = SnapshotScannerError.captureFailed(hostilePOSIX)
        let providerError = SnapshotScannerError.captureFailed(hostileProvider)

        // Two different arbitrary diagnostics must produce the same bounded
        // visible capture text, and none of the hostile tokens may leak.
        let first = CaptureErrorDescription.message(for: sqliteError)
        let second = CaptureErrorDescription.message(for: posixError)
        let third = CaptureErrorDescription.message(for: providerError)

        XCTAssertEqual(first, second)
        XCTAssertEqual(second, third)
        XCTAssertEqual(
            first,
            "Metadata capture failed. Verify that the source is available and try again."
        )
        for token in ["SQLITE_CORRUPT", "/Users/secret", "/private/var/fsd", "errno", "provider-detail", "0x7f00", "catalog.sqlite3"] {
            XCTAssertFalse(first.contains(token), "hostile token \(token) reached visible capture text")
        }
    }

    func testCaptureFailureWrapperFormsAreIdentical() {
        // The generic entry point must route scanner errors to the same
        // bounded mapping as the typed entry point.
        let typed = CaptureErrorDescription.message(for: SnapshotScannerError.captureFailed(hostileSQLite))
        let wrapped = CaptureErrorDescription.message(for: SnapshotScannerError.captureFailed(hostileSQLite) as Error)
        XCTAssertEqual(typed, wrapped)
    }

    // MARK: - Typed distinctions stay bounded and distinct

    func testTypedCaptureDistinctionsRemainBounded() {
        let messages: [(String, String)] = [
            // Capture failure (arbitrary payload) — fixed retry text.
            (
                CaptureErrorDescription.message(for: SnapshotScannerError.captureFailed(hostileSQLite)),
                "Metadata capture failed. Verify that the source is available and try again."
            ),
            // Provider / unavailable source — distinct from capture failure.
            (
                CaptureErrorDescription.message(for: SnapshotScannerError.provider(.invalidSource(hostileSQLite))),
                "The selected source is not readable as a metadata source."
            ),
            (
                CaptureErrorDescription.message(for: SnapshotScannerError.provider(.metadataUnavailable(hostilePOSIX))),
                "Metadata for the selected source could not be read."
            ),
            (
                CaptureErrorDescription.message(for: SnapshotScannerError.provider(.outsideSelectedRoot("/private/var/fsd"))),
                "The selected source is not readable as a metadata source."
            ),
            // Cancellation — remains distinct and bounded.
            (
                CaptureErrorDescription.message(for: SnapshotScannerError.provider(.cancelled)),
                "The capture was cancelled."
            ),
            // Catalog / database failure — bounded, no raw SQLite message.
            (
                CaptureErrorDescription.message(for: SnapshotScannerError.writer(.database(.sqlite(11, hostileSQLite)))),
                "The capture could not be recorded in the catalog."
            ),
            // Detector failure — bounded.
            (
                CaptureErrorDescription.message(for: SnapshotScannerError.detector(.cannotReadMetadata(hostilePOSIX))),
                "The source type could not be identified."
            ),
            // Generic catalog error through the generic entry point.
            (
                CaptureErrorDescription.message(for: CatalogDatabaseError.sqlite(8, hostileSQLite) as Error),
                "The catalog could not record the capture."
            ),
            // Unknown error — fixed fallback.
            (
                CaptureErrorDescription.message(for: NSError(domain: "FSDTest", code: 1, userInfo: [NSLocalizedDescriptionKey: hostileProvider])),
                "The capture could not be completed."
            ),
        ]
        for (actual, expected) in messages {
            XCTAssertEqual(actual, expected)
        }
        // The categories that must be distinguishable have distinct fixed
        // wording (invalidSource and outsideSelectedRoot deliberately share
        // one "not readable" text — the user-facing distinction is the same);
        // none of the visible strings carries a hostile token.
        let all = messages.map(\.0)
        for pair in [(0, 1), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 4), (4, 5), (4, 6), (5, 6), (6, 8)] {
            XCTAssertNotEqual(all[pair.0], all[pair.1], "categories \(pair.0) and \(pair.1) must stay distinct")
        }
        XCTAssertEqual(all[1], all[3], "invalidSource and outsideSelectedRoot share the same bounded source text")
        for message in all {
            for token in ["SQLITE_CORRUPT", "/Users/secret", "/private/var", "errno", "provider-detail", "0x7f00"] {
                XCTAssertFalse(message.contains(token), "hostile token \(token) reached \(message)")
            }
        }
    }

    func testCancellationRemainsDistinctFromFailure() {
        XCTAssertNotEqual(
            CaptureErrorDescription.message(for: SnapshotScannerError.provider(.cancelled)),
            CaptureErrorDescription.message(for: SnapshotScannerError.captureFailed(hostileSQLite))
        )
        XCTAssertNotEqual(
            CaptureErrorDescription.message(for: CancellationError() as Error),
            CaptureErrorDescription.message(for: SnapshotScannerError.captureFailed(hostileSQLite))
        )
    }

    // MARK: - Source boundary: the legacy capture UI no longer renders raw text

    func testLegacyCaptureUISourceAssignsOnlyBoundedFailureText() throws {
        let appPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // FSDTests
            .deletingLastPathComponent() // repo root
            .appendingPathComponent("FSD/App/FSDApp.swift")
        let source = try String(contentsOf: appPath, encoding: .utf8)

        XCTAssertFalse(
            source.contains(".failed(error.localizedDescription)"),
            "FSDApp.swift must not assign raw localizedDescription to the visible capture state"
        )
        XCTAssertTrue(
            source.contains("CaptureErrorDescription.message(for: error)"),
            "FSDApp.swift must route visible capture failures through the bounded mapper"
        )
        XCTAssertTrue(
            source.contains("CaptureErrorDescription.diagnosticLine(for: error)"),
            "FSDApp.swift must retain the raw diagnostic on the internal diagnostic channel"
        )
    }

    func testDiagnosticChannelKeepsRawTextForDiagnostics() {
        // The internal diagnostic line preserves the hostile detail even
        // though the visible text does not.
        let diagnostic = CaptureErrorDescription.diagnosticLine(for: SnapshotScannerError.captureFailed(hostileSQLite))
        XCTAssertTrue(diagnostic.contains("SQLITE_CORRUPT"))
        XCTAssertTrue(diagnostic.contains("/Users/secret"))
    }
}
