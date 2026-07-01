import Foundation

public struct SnoozeEntry: Codable, Sendable, Identifiable {
    public var id: String { threadID }
    public let threadID: String
    public let wakeDate: Date

    public init(threadID: String, wakeDate: Date) {
        self.threadID = threadID
        self.wakeDate = wakeDate
    }
}
