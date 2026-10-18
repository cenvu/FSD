import Foundation

/// A random catalog reference. It carries no hardware identity claim.
public struct PhysicalDriveID: Hashable, Sendable {
    public let rawValue: UUID
    public init(rawValue: UUID = UUID()) { self.rawValue = rawValue }
}

public struct PhysicalDrive: Equatable, Sendable {
    public let id: PhysicalDriveID
    public let label: String?
    public let provenance: String
    public let revision: Int64
    public let retired: Bool
    public let createdAt: String
    public let updatedAt: String
    public var hardwareVerified: Bool { false }
}

public enum IdentityScope: String, Sendable, CaseIterable {
    case device, media, partition, volume, mountSession
}
public enum IdentityObservationState: String, Sendable { case unknown, ambiguous, conflict }
public enum IdentityEvidenceProvider: String, Sendable { case synthetic, diskArbitration, ioKit, foundation }
/// Validated means the caller validated a typed fact, never hardware uniqueness.
public enum IdentityEvidenceValidation: String, Sendable { case unverified, validated, unknown, conflict }
public enum IdentityEvidenceKind: String, Sendable, CaseIterable {
    case filesystemUUID, mediaUUID, partitionUUID, deviceSerial, displayName, mountPath, bsdNode, vendorModel
    public var scope: IdentityScope {
        switch self {
        case .filesystemUUID, .displayName: return .volume
        case .mediaUUID: return .media
        case .partitionUUID: return .partition
        case .deviceSerial, .vendorModel: return .device
        case .mountPath, .bsdNode: return .mountSession
        }
    }
    /// Provider aliases of one property share this host-defined group.
    public var dependencyGroup: String { rawValue }
    public var isUUID: Bool { [.filesystemUUID, .mediaUUID, .partitionUUID].contains(self) }
}
public struct IdentityEvidenceInput: Equatable, Sendable {
    public let kind: IdentityEvidenceKind
    public let provider: IdentityEvidenceProvider
    public let property: String
    public let value: String?
    public let validation: IdentityEvidenceValidation
    public let provenance: String
    public init(kind: IdentityEvidenceKind, provider: IdentityEvidenceProvider, property: String,
                value: String?, validation: IdentityEvidenceValidation = .unverified, provenance: String) {
        self.kind = kind; self.provider = provider; self.property = property
        self.value = value; self.validation = validation; self.provenance = provenance
    }
}
public struct IdentityObservation: Equatable, Sendable {
    public let id: UUID
    public let sessionID: UUID
    public let revision: Int64
    public let scope: IdentityScope
    public let state: IdentityObservationState
    public let provenance: String
    public let observedAt: String
}
public struct IdentityEvidence: Equatable, Sendable {
    public let id: UUID
    public let observationID: UUID
    public let observationRevision: Int64
    public let scope: IdentityScope
    public let fact: IdentityEvidenceInput
    public let observedAt: String
    public var dependencyGroup: String { fact.kind.dependencyGroup }
}
public enum ManualAssociationAction: String, Sendable { case associate, correct, revoke }
public struct ManualDriveAssociation: Equatable, Sendable {
    public let operationID: UUID
    public let observationID: UUID
    public let observationRevision: Int64
    public let revision: Int64
    public let previousEventID: UUID?
    public let target: PhysicalDriveID?
    public let targetRevision: Int64?
    public let action: ManualAssociationAction
    public let actor: String
    public let reason: String
    public let createdAt: String
}
public enum PhysicalDriveResolution: Equatable, Sendable {
    case unknown, ambiguous, conflict
    case manualAssociation(PhysicalDriveID)
    /// Reserved for a future approved profile. No Task058 API produces this.
    case uniqueStrongMatch(PhysicalDriveID)
}
public struct IdentityPage<Element: Sendable>: Sendable {
    public let records: [Element]
    public let isTruncated: Bool
}
public enum PhysicalDriveIdentityError: Error, Equatable {
    case invalidInput, notFound, staleRevision, retired, conflict, operationMismatch, corruptRecord
}
