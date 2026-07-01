import Foundation

public actor GmailAPIClient {
    private var tokens: OAuthTokens
    private let clientID: String
    private let clientSecret: String
    public let accountID: String

    private static let base = URL(string: "https://www.googleapis.com/gmail/v1/users/me")!

    public init(tokens: OAuthTokens, clientID: String, clientSecret: String, accountID: String) {
        self.tokens = tokens
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.accountID = accountID
    }

    // MARK: - Public API

    public func getProfile() async throws -> GmailProfile {
        try await get("profile", as: GmailProfile.self)
    }

    func listThreads(maxResults: Int = 25, labelIDs: [String] = ["INBOX"], pageToken: String? = nil) async throws -> GmailThreadsList {
        var params: [String: String] = ["maxResults": "\(maxResults)"]
        if let label = labelIDs.first { params["labelIds"] = label }
        if let t = pageToken { params["pageToken"] = t }
        return try await get("threads", params: params, as: GmailThreadsList.self)
    }

    func getThread(_ id: String, format: String = "metadata") async throws -> GmailThread {
        try await get("threads/\(id)", params: ["format": format], as: GmailThread.self)
    }

    /// Fetches a thread with full body content for rendering in the reading pane.
    public func getFullThread(_ id: String) async throws -> MailThread {
        let thread: GmailThread = try await get("threads/\(id)", params: ["format": "full"], as: GmailThread.self)
        return GmailMessageMapper.mapThread(thread, accountID: accountID)
    }

    /// Searches all of Gmail using native query syntax (from:, has:attachment, etc.).
    public func searchThreads(query: String, maxResults: Int = 50) async throws -> ([MailThread], nextPageToken: String?) {
        let params: [String: String] = ["maxResults": "\(maxResults)", "q": query]
        let listing = try await get("threads", params: params, as: GmailThreadsList.self)
        return (try await fetchThreads(stubs: listing.threads ?? []), listing.nextPageToken)
    }

    /// High-level: lists threads then fetches metadata for each in parallel.
    /// Returns (threads, nextPageToken) — pass the token to loadMoreThreads() to paginate.
    public func syncInbox() async throws -> ([MailThread], nextPageToken: String?) {
        let listing = try await listThreads(maxResults: 25)
        return (try await fetchThreads(stubs: listing.threads ?? []), listing.nextPageToken)
    }

    /// Fetches the next page of inbox threads.
    public func loadMoreThreads(pageToken: String) async throws -> ([MailThread], nextPageToken: String?) {
        let listing = try await listThreads(maxResults: 25, pageToken: pageToken)
        return (try await fetchThreads(stubs: listing.threads ?? []), listing.nextPageToken)
    }

    /// Sends a new outbound message (not threaded — use sendReply for replies).
    public func sendNew(from: String, to: [String], subject: String, plainBody: String) async throws {
        let mime = [
            "From: \(from)",
            "To: \(to.joined(separator: ", "))",
            "Subject: \(subject)",
            "MIME-Version: 1.0",
            "Content-Type: text/plain; charset=UTF-8"
        ].joined(separator: "\r\n") + "\r\n\r\n" + plainBody
        struct SendBody: Encodable { let raw: String }
        try await postJSON("messages/send", body: SendBody(raw: Data(mime.utf8).base64URLEncoded()))
    }

    private func fetchThreads(stubs: [GmailThreadsList.GmailThreadStub]) async throws -> [MailThread] {
        guard !stubs.isEmpty else { return [] }
        var results: [MailThread] = []
        try await withThrowingTaskGroup(of: MailThread.self) { group in
            for stub in stubs {
                group.addTask {
                    let t = try await self.getThread(stub.id)
                    return GmailMessageMapper.mapThread(t, accountID: self.accountID)
                }
            }
            for try await thread in group { results.append(thread) }
        }
        return results.sorted { $0.lastMessageDate > $1.lastMessageDate }
    }

    // MARK: - Mutations

    /// Add or remove Gmail labels on a thread. Use this for mark-as-read, archive, star, etc.
    public func modifyThread(_ id: String, addLabels: [String] = [], removeLabels: [String] = []) async throws {
        struct Body: Encodable { let addLabelIds: [String]; let removeLabelIds: [String] }
        try await postJSON("threads/\(id)/modify", body: Body(addLabelIds: addLabels, removeLabelIds: removeLabels))
    }

    /// Sends a plain-text reply and attaches it to the existing thread.
    public func sendReply(
        threadID: String,
        inReplyToMessageID: String?,
        from: String,
        to: [String],
        subject: String,
        plainBody: String
    ) async throws {
        let sub = subject.hasPrefix("Re: ") ? subject : "Re: \(subject)"
        var headers = [
            "From: \(from)",
            "To: \(to.joined(separator: ", "))",
            "Subject: \(sub)",
            "MIME-Version: 1.0",
            "Content-Type: text/plain; charset=UTF-8"
        ]
        if let mid = inReplyToMessageID {
            headers.append("In-Reply-To: \(mid)")
            headers.append("References: \(mid)")
        }
        let mime = headers.joined(separator: "\r\n") + "\r\n\r\n" + plainBody
        let raw = Data(mime.utf8).base64URLEncoded()

        struct SendBody: Encodable { let raw: String; let threadId: String }
        try await postJSON("messages/send", body: SendBody(raw: raw, threadId: threadID))
    }

    // MARK: - Token management

    public func currentTokens() -> OAuthTokens { tokens }

    func updateTokens(_ t: OAuthTokens) { tokens = t }

    // MARK: - HTTP helpers

    private func validToken() async throws -> String {
        if tokens.isExpired {
            let auth = AuthService(clientID: clientID, clientSecret: clientSecret)
            tokens = try await auth.refresh(tokens: tokens)
        }
        return tokens.accessToken
    }

    private func postJSON<T: Encodable>(_ path: String, body: T) async throws {
        let token = try await validToken()
        var req = URLRequest(url: Self.base.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw GmailError.requestFailed(String(data: data, encoding: .utf8) ?? "unknown")
        }
    }

    private func get<T: Decodable>(_ path: String, params: [String: String] = [:], as type: T.Type) async throws -> T {
        let token = try await validToken()
        var comps = URLComponents(url: Self.base.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !params.isEmpty {
            comps.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        var req = URLRequest(url: comps.url!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw GmailError.requestFailed(String(data: data, encoding: .utf8) ?? "unknown")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

private extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

public enum GmailError: Error, LocalizedError {
    case requestFailed(String)

    public var errorDescription: String? {
        switch self {
        case .requestFailed(let body): return "Gmail API error: \(body)"
        }
    }
}
