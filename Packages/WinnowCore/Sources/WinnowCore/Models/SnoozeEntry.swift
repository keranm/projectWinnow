import Foundation

public enum SnoozeCondition: String, Codable, Hashable, Sendable {
    case onReply = "onReply"
}

public struct SnoozeEntry: Codable, Sendable, Identifiable {
    public var id: String { threadID }
    public let threadID: String
    public let wakeDate: Date?
    public let condition: SnoozeCondition?
    public let messageCountAtSnooze: Int

    public init(threadID: String, wakeDate: Date) {
        self.threadID = threadID
        self.wakeDate = wakeDate
        self.condition = nil
        self.messageCountAtSnooze = 0
    }

    public init(threadID: String, condition: SnoozeCondition, messageCount: Int) {
        self.threadID = threadID
        self.wakeDate = nil
        self.condition = condition
        self.messageCountAtSnooze = messageCount
    }

    public func isExpired(now: Date = Date()) -> Bool {
        guard let wakeDate else { return false }
        return now >= wakeDate
    }

    public func isTriggered(by thread: MailThread) -> Bool {
        guard let condition else { return false }
        switch condition {
        case .onReply:
            return thread.messages.count > messageCountAtSnooze
        }
    }
}
