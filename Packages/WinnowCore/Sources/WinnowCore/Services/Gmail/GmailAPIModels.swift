import Foundation

// MARK: - Thread listing

struct GmailThreadsList: Decodable {
    let threads: [GmailThreadStub]?
    let nextPageToken: String?
    let resultSizeEstimate: Int?

    struct GmailThreadStub: Decodable {
        let id: String
        let snippet: String?
        let historyId: String?
    }
}

// MARK: - Full thread

struct GmailThread: Decodable {
    let id: String
    let historyId: String?
    let messages: [GmailMessage]?
}

// MARK: - Message

struct GmailMessage: Decodable {
    let id: String
    let threadId: String?
    let labelIds: [String]?
    let snippet: String?
    let payload: Part?
    let internalDate: String?   // milliseconds since epoch as a string

    struct Part: Decodable {
        let headers: [Header]?
        let body: Body?
        let parts: [Part]?
        let mimeType: String?

        struct Header: Decodable {
            let name: String
            let value: String
        }

        struct Body: Decodable {
            let size: Int?
            let data: String?   // base64url encoded
        }
    }

    // Convenience header lookup
    func header(_ name: String) -> String? {
        payload?.headers?.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.value
    }

    /// Recursively extracts plain-text body from message parts.
    var plainTextBody: String? {
        extractPlainText(from: payload)
    }

    private func extractPlainText(from part: Part?) -> String? {
        guard let part else { return nil }
        if part.mimeType == "text/plain", let data = part.body?.data {
            return Data(base64URLEncoded: data).flatMap { String(data: $0, encoding: .utf8) }
        }
        for sub in part.parts ?? [] {
            if let text = extractPlainText(from: sub) { return text }
        }
        return nil
    }
}

// MARK: - Profile

public struct GmailProfile: Decodable, Sendable {
    public let emailAddress: String
    public let messagesTotal: Int?
    public let historyId: String?
}

// MARK: - Data base64url helper

extension Data {
    init?(base64URLEncoded string: String) {
        let base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padded = base64 + String(repeating: "=", count: (4 - base64.count % 4) % 4)
        self.init(base64Encoded: padded)
    }
}
