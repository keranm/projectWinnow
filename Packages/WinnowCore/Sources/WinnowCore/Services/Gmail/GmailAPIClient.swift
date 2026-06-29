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
        for id in labelIDs { params["labelIds"] = id } // last wins — fine for single label
        if !labelIDs.isEmpty { params["labelIds"] = labelIDs.joined(separator: "&labelIds=") }
        if let t = pageToken { params["pageToken"] = t }
        return try await get("threads", params: params, as: GmailThreadsList.self)
    }

    func getThread(_ id: String, format: String = "metadata") async throws -> GmailThread {
        var params = ["format": format]
        if format == "metadata" {
            params["metadataHeaders"] = "From,To,Subject,Date"
        }
        return try await get("threads/\(id)", params: params, as: GmailThread.self)
    }

    /// High-level: lists threads then fetches metadata for each in parallel.
    public func syncInbox() async throws -> [MailThread] {
        let listing = try await listThreads(maxResults: 25)
        let stubs = listing.threads ?? []
        guard !stubs.isEmpty else { return [] }

        var results: [MailThread] = []
        try await withThrowingTaskGroup(of: MailThread.self) { group in
            for stub in stubs {
                group.addTask {
                    let t = try await self.getThread(stub.id)
                    return GmailMessageMapper.mapThread(t, accountID: self.accountID)
                }
            }
            for try await thread in group {
                results.append(thread)
            }
        }
        return results.sorted { $0.lastMessageDate > $1.lastMessageDate }
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

public enum GmailError: Error, LocalizedError {
    case requestFailed(String)

    public var errorDescription: String? {
        switch self {
        case .requestFailed(let body): return "Gmail API error: \(body)"
        }
    }
}
