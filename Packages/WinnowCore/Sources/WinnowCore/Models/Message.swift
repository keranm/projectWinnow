import Foundation

public struct MailMessage: Identifiable, Sendable, Hashable, Codable {
    public let id: String
    public let threadID: String
    public let accountID: String
    public var from: Participant
    public var to: [Participant]
    public var cc: [Participant]
    public var subject: String
    public var snippet: String
    public var body: MessageBody?
    public var date: Date
    public var labels: Set<String>
    public var isRead: Bool
    /// RFC 2822 Message-ID header value — used for reply threading.
    public var rfc2822MessageID: String?

    public init(
        id: String,
        threadID: String,
        accountID: String,
        from: Participant,
        to: [Participant],
        cc: [Participant] = [],
        subject: String,
        snippet: String,
        body: MessageBody? = nil,
        date: Date,
        labels: Set<String> = [],
        isRead: Bool = false,
        rfc2822MessageID: String? = nil
    ) {
        self.id = id
        self.threadID = threadID
        self.accountID = accountID
        self.from = from
        self.to = to
        self.cc = cc
        self.subject = subject
        self.snippet = snippet
        self.body = body
        self.date = date
        self.labels = labels
        self.isRead = isRead
        self.rfc2822MessageID = rfc2822MessageID
    }
}

public struct Participant: Sendable, Hashable, Codable {
    public let name: String?
    public let email: String

    public init(name: String? = nil, email: String) {
        self.name = name
        self.email = email
    }

    public var displayName: String { name ?? email }
}

public enum MessageBody: Sendable, Hashable, Codable {
    case plain(String)
    case html(String)
}
