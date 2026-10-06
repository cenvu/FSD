import Foundation

/// The only input a classification provider ever receives: an immutable,
/// bounded prefix of one selected file's bytes.
///
/// The request deliberately has exactly one stored field. It carries no path,
/// URL, file handle, entry/snapshot/volume identity, metadata, reader or range
/// callback, resolver, or filesystem abstraction, and it offers no way to ask
/// for more bytes. Only FSD's source reader (`BoundedClassificationSourceReader`)
/// constructs it, after it has re-resolved the source, validated its identity
/// and performed the single no-follow prefix read. There is no public
/// initializer, and the module-internal one rejects anything above the ceiling,
/// so an over-budget request cannot exist.
public struct LocalClassificationRequest: Sendable, Hashable {
    /// Locked prefix ceiling for classification-only content access.
    public static let maximumByteCount = 4096

    /// Immutable prefix bytes, at most `maximumByteCount` long.
    public let data: Data

    /// Returns nil when `prefix` exceeds the ceiling. The bytes are copied so a
    /// request never shares storage with a larger buffer.
    init?(boundedPrefix prefix: Data) {
        guard prefix.count <= Self.maximumByteCount else { return nil }
        self.data = Data(prefix)
    }
}

public struct LocalClassificationObservation: Sendable, Hashable {
    public let detectedType: String?
    public let mimeType: String?
    public let confidence: Double?
    public let detectorVersion: String?
    public let modelVersion: String?
    public let classifiedAt: String?

    public init(
        detectedType: String?,
        mimeType: String? = nil,
        confidence: Double? = nil,
        detectorVersion: String? = nil,
        modelVersion: String? = nil,
        classifiedAt: String? = nil
    ) {
        self.detectedType = detectedType
        self.mimeType = mimeType
        self.confidence = confidence
        self.detectorVersion = detectorVersion
        self.modelVersion = modelVersion
        self.classifiedAt = classifiedAt
    }
}

/// The complete, closed outcome vocabulary of one classification attempt.
/// Providers normally produce `classified`, `noMatch`, `failed`, `unavailable` and
/// `cancelled`; FSD's pre-provider reader produces `sourceChanged` and
/// `unsupportedEntry` (and may produce the other outcomes before any provider
/// call). Nothing here carries a diagnostic string, path, or sampled byte.
public enum LocalClassificationProviderResult: Sendable, Hashable {
    case classified(LocalClassificationObservation)
    case failed
    case sourceChanged
    case unsupportedEntry
    case unavailable
    case cancelled
    /// The provider ran successfully but recognized no type; no metadata or row.
    case noMatch
}

/// Future local adapters implement this protocol. It exposes no raw diagnostic
/// channel, no networking hook, no throwing path that could carry error text,
/// and receives bytes only. Cancellation is observed through structured
/// concurrency; a cancelled call should return `.cancelled`.
public protocol LocalFileClassificationProvider: Sendable {
    var providerIdentifier: String { get }
    var detectorVersion: String? { get }
    var modelVersion: String? { get }
    func classify(_ request: LocalClassificationRequest) async -> LocalClassificationProviderResult
}

/// The only built-in provider in this slice. It performs no filesystem access,
/// no I/O of any kind, keeps no state and never inspects the request bytes.
public struct DisabledFileClassificationProvider: LocalFileClassificationProvider {
    public let providerIdentifier = "disabled"
    public let detectorVersion: String? = nil
    public let modelVersion: String? = nil

    public init() {}

    public func classify(_ request: LocalClassificationRequest) async -> LocalClassificationProviderResult {
        .unavailable
    }
}
