import Darwin
import Foundation

/// Exclusive, catalog-scoped ownership for one process.
///
/// Condition C5 of the Milestone 2 acceptance audit: `RecoveryService` converts
/// every `scanning` snapshot to `interrupted` at startup with no ownership
/// check, so a second FSD instance launched during a live capture would mark
/// that capture interrupted. The running capture then failed safely rather than
/// corrupting data, but the single-process assumption was neither enforced nor
/// documented.
///
/// The mechanism is a lock file beside the catalog plus a non-blocking advisory
/// `flock`. It is deliberately the smallest thing that works:
///
/// * the lock is per catalog, so tests and probes using separate `/tmp`
///   catalogs never contend;
/// * `flock` is held by the open file description, so the kernel releases it
///   when the owning process exits for any reason, including a crash or a
///   force-quit — a stale lock file can never permanently block startup;
/// * nothing is written to any scanned source; the lock file lives next to the
///   catalog, inside Application Support or the overridden catalog directory.
///
/// This is not distributed coordination and must not grow into any.
public final class CatalogProcessLock {
    public enum LockError: Error, LocalizedError, Equatable {
        case alreadyLocked(URL, pid_t?)
        case cannotCreate(URL, String)

        public var errorDescription: String? {
            switch self {
            case let .alreadyLocked(url, pid):
                let owner = pid.map { " (process \($0))" } ?? ""
                return """
                Another copy of FishSock Differ is already using this catalog\(owner). \
                Only one FSD process may use a catalog at a time, so that a capture in \
                progress is never mistaken for an interrupted one. Quit the other copy \
                and try again. Catalog: \(url.path)
                """
            case let .cannotCreate(url, message):
                return "Cannot create the catalog lock file at \(url.path): \(message)"
            }
        }
    }

    public let lockURL: URL
    private var descriptor: Int32 = -1
    private let lock = NSLock()

    /// Acquires the lock, or throws `LockError.alreadyLocked` immediately.
    public init(catalogURL: URL) throws {
        lockURL = catalogURL.appendingPathExtension("lock")

        do {
            try FileManager.default.createDirectory(
                at: lockURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            throw LockError.cannotCreate(lockURL, error.localizedDescription)
        }

        let fd = lockURL.path.withCString { open($0, O_CREAT | O_RDWR, 0o644) }
        guard fd >= 0 else {
            throw LockError.cannotCreate(lockURL, String(cString: strerror(errno)))
        }

        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else {
            let holder = Self.recordedProcessIdentifier(fileDescriptor: fd)
            close(fd)
            throw LockError.alreadyLocked(lockURL, holder)
        }

        descriptor = fd
        writeOwnProcessIdentifier()
    }

    deinit { unlock() }

    /// Releases the lock. Idempotent.
    public func unlock() {
        lock.lock()
        defer { lock.unlock() }
        guard descriptor >= 0 else { return }
        flock(descriptor, LOCK_UN)
        close(descriptor)
        descriptor = -1
    }

    public var isHeld: Bool {
        lock.lock()
        defer { lock.unlock() }
        return descriptor >= 0
    }

    /// Diagnostic only. The lock itself is the advisory `flock`, never this text.
    private func writeOwnProcessIdentifier() {
        guard descriptor >= 0 else { return }
        ftruncate(descriptor, 0)
        lseek(descriptor, 0, SEEK_SET)
        let payload = "\(getpid())\n"
        _ = payload.withCString { pointer in
            write(descriptor, pointer, strlen(pointer))
        }
        fsync(descriptor)
    }

    private static func recordedProcessIdentifier(fileDescriptor: Int32) -> pid_t? {
        var buffer = [CChar](repeating: 0, count: 32)
        lseek(fileDescriptor, 0, SEEK_SET)
        let count = read(fileDescriptor, &buffer, buffer.count - 1)
        guard count > 0 else { return nil }
        let text = String(cString: buffer).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int32(text), value > 0 else { return nil }
        return value
    }
}
