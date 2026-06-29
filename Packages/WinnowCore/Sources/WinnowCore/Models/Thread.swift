import Foundation

public struct MailThread: Identifiable, Sendable {
    public let id: String
    public let accountID: String
    public var subject: String
    public var snippet: String
    public var messages: [MailMessage]
    public var labels: Set<String>
    public var isRead: Bool
    public var isStarred: Bool
    public var lastMessageDate: Date

    public init(
        id: String,
        accountID: String,
        subject: String,
        snippet: String,
        messages: [MailMessage] = [],
        labels: Set<String> = [],
        isRead: Bool = false,
        isStarred: Bool = false,
        lastMessageDate: Date
    ) {
        self.id = id
        self.accountID = accountID
        self.subject = subject
        self.snippet = snippet
        self.messages = messages
        self.labels = labels
        self.isRead = isRead
        self.isStarred = isStarred
        self.lastMessageDate = lastMessageDate
    }
}
