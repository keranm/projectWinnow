import Foundation

/// The local thread store (ADR 001 — the mailbox lives on this device, nowhere else).
///
/// Launch paints the mailbox from here in milliseconds while the network sync refreshes
/// in the background. Saves are whole-store atomic writes; callers debounce.
public actor ThreadCache {
    public static let shared = ThreadCache()
    private init() {}

    public func load() -> [MailThread] {
        guard let url = try? fileURL(),
              let data = try? Data(contentsOf: url),
              let threads = try? JSONDecoder().decode([MailThread].self, from: data)
        else { return [] }
        return threads
    }

    public func save(_ threads: [MailThread]) {
        guard let url = try? fileURL(),
              let data = try? JSONEncoder().encode(threads)
        else { return }
        try? data.write(to: url, options: .atomic)
    }

    public func clear() {
        guard let url = try? fileURL() else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private func fileURL() throws -> URL {
        let dir = try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Winnow", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("threads.json")
    }
}
