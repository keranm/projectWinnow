import Foundation
import CryptoKit
import Security

/// Orchestrates the OAuth 2.0 PKCE flow for an "installed" desktop app.
/// Opens a browser, captures the loopback redirect, exchanges the code for tokens.
public actor AuthService {
    private let clientID: String
    private let clientSecret: String

    private let scopes = [
        "https://www.googleapis.com/auth/gmail.modify",
        "email",
        "profile"
    ]

    public init(clientID: String, clientSecret: String) {
        self.clientID = clientID
        self.clientSecret = clientSecret
    }

    /// Runs the full auth flow. `openURL` should open the URL in the user's browser.
    public func authenticate(openURL: @Sendable (URL) -> Void) async throws -> OAuthTokens {
        let verifier   = generateVerifier()
        let challenge  = try sha256Challenge(from: verifier)

        let server = OAuthLocalServer()
        try await server.start()
        let port = await server.port
        let redirectURI = "http://127.0.0.1:\(port)"

        let authURL = try buildAuthURL(redirectURI: redirectURI, challenge: challenge)
        openURL(authURL)

        let code = try await server.captureCode()
        await server.stop()

        return try await exchange(code: code, redirectURI: redirectURI, verifier: verifier)
    }

    public func refresh(tokens: OAuthTokens) async throws -> OAuthTokens {
        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(name: "client_id",     value: clientID),
            URLQueryItem(name: "client_secret", value: clientSecret),
            URLQueryItem(name: "refresh_token", value: tokens.refreshToken),
            URLQueryItem(name: "grant_type",    value: "refresh_token")
        ]
        return try await post(body: body.percentEncodedQuery ?? "",
                              existingRefreshToken: tokens.refreshToken)
    }

    // MARK: - Private

    private func buildAuthURL(redirectURI: String, challenge: String) throws -> URL {
        var comps = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        comps.queryItems = [
            URLQueryItem(name: "client_id",             value: clientID),
            URLQueryItem(name: "redirect_uri",          value: redirectURI),
            URLQueryItem(name: "response_type",         value: "code"),
            URLQueryItem(name: "scope",                 value: scopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge",        value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type",           value: "offline"),
            URLQueryItem(name: "prompt",                value: "consent")
        ]
        guard let url = comps.url else { throw OAuthError.pkceGenerationFailed }
        return url
    }

    private func exchange(code: String, redirectURI: String, verifier: String) async throws -> OAuthTokens {
        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(name: "code",          value: code),
            URLQueryItem(name: "client_id",     value: clientID),
            URLQueryItem(name: "client_secret", value: clientSecret),
            URLQueryItem(name: "redirect_uri",  value: redirectURI),
            URLQueryItem(name: "grant_type",    value: "authorization_code"),
            URLQueryItem(name: "code_verifier", value: verifier)
        ]
        return try await post(body: body.percentEncodedQuery ?? "", existingRefreshToken: nil)
    }

    private func post(body: String, existingRefreshToken: String?) async throws -> OAuthTokens {
        var req = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw OAuthError.tokenExchangeFailed(String(data: data, encoding: .utf8) ?? "unknown")
        }

        struct TokenResponse: Decodable {
            let access_token: String
            let expires_in: Int
            let refresh_token: String?
        }
        let tr = try JSONDecoder().decode(TokenResponse.self, from: data)

        return OAuthTokens(
            accessToken:  tr.access_token,
            refreshToken: tr.refresh_token ?? existingRefreshToken ?? "",
            expiresAt:    Date().addingTimeInterval(Double(tr.expires_in))
        )
    }

    // MARK: - PKCE

    private func generateVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncoded()
    }

    private func sha256Challenge(from verifier: String) throws -> String {
        guard let data = verifier.data(using: .utf8) else { throw OAuthError.pkceGenerationFailed }
        return Data(SHA256.hash(data: data)).base64URLEncoded()
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
