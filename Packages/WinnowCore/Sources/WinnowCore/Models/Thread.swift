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

    // Triage
    public var needsReply: Bool
    public var hasDraftReady: Bool

    // On-device intelligence (tier 2/3 outputs)
    public var summary: String?
    public var suggestedReplies: [String]
    public var intelligenceResults: [IntelligenceResult]

    public init(
        id: String,
        accountID: String,
        subject: String,
        snippet: String,
        messages: [MailMessage] = [],
        labels: Set<String> = [],
        isRead: Bool = false,
        isStarred: Bool = false,
        lastMessageDate: Date,
        needsReply: Bool = false,
        hasDraftReady: Bool = false,
        summary: String? = nil,
        suggestedReplies: [String] = [],
        intelligenceResults: [IntelligenceResult] = []
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
        self.needsReply = needsReply
        self.hasDraftReady = hasDraftReady
        self.summary = summary
        self.suggestedReplies = suggestedReplies
        self.intelligenceResults = intelligenceResults
    }
}
