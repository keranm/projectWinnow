import Foundation

public struct OAuthTokens: Sendable, Codable {
    public var accessToken: String
    public var refreshToken: String
    public var expiresAt: Date

    /// True when the token has less than 60 s of life left.
    public var isExpired: Bool {
        Date() >= expiresAt.addingTimeInterval(-60)
    }

    public init(accessToken: String, refreshToken: String, expiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }
}
