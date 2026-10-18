import Foundation

public struct DriveSetID: Hashable, Sendable {
    public let rawValue: UUID
    public init(rawValue: UUID = UUID()) { self.rawValue = rawValue }
}
public struct DriveSet: Equatable, Sendable {
    public let id: DriveSetID
    public let name: String
    public let normalizedName: String
    public let revision: Int64
    public let createdAt: String
    public let updatedAt: String
}
public struct DriveSetCursor: Equatable, Sendable {
    public let normalizedName: String
    public let id: DriveSetID
}
public struct DriveSetPage: Sendable {
    public let records: [DriveSet]
    public let next: DriveSetCursor?
}
public enum DriveSetError: Error, Equatable, LocalizedError {
    case invalidName, duplicateName, notFound, staleRevision, missingDrive, retiredDrive, operationMismatch, corruptRecord
    public var errorDescription: String? {
        switch self {
        case .invalidName: return "Enter a name of 1–256 UTF-8 bytes without null characters."
        case .duplicateName: return "A Drive Set with that name already exists."
        case .notFound: return "That Drive Set is no longer available. Refresh and try again."
        case .staleRevision: return "This record changed. Refresh and try again."
        case .missingDrive: return "That local drive record is no longer available."
        case .retiredDrive: return "A retired local record cannot be added to a Drive Set."
        case .operationMismatch: return "This operation no longer matches the saved record. Refresh and try again."
        case .corruptRecord: return "The saved Drive Set could not be read."
        }
    }
}
