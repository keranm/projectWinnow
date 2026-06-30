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

    var plainTextBody: String? { extractBody(from: payload, mimeType: "text/plain") }
    var htmlBody: String?      { extractBody(from: payload, mimeType: "text/html") }

    private func extractBody(from part: Part?, mimeType: String) -> String? {
        guard let part else { return nil }
        if part.mimeType?.hasPrefix(mimeType) == true,
           let data = part.body?.data, !data.isEmpty {
            return Data(base64URLEncoded: data).flatMap { String(data: $0, encoding: .utf8) }
        }
        for sub in part.parts ?? [] {
            if let result = extractBody(from: sub, mimeType: mimeType) { return result }
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

// MARK: - HTML entity decoding

extension String {
    var decodingHTMLEntities: String {
        guard contains("&") else { return self }
        return self
            .replacingOccurrences(of: "&amp;",  with: "&")
            .replacingOccurrences(of: "&lt;",   with: "<")
            .replacingOccurrences(of: "&gt;",   with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;",  with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }
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
