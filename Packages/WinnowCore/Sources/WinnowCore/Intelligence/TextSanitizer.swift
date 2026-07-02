import Foundation

/// Shared plain-text preparation for intelligence tiers — turns message bodies into
/// clean text for extractors and generation prompts.
enum TextSanitizer {

    /// Best-available plain text for a message: body if loaded (HTML stripped), else snippet.
    static func plainText(for message: MailMessage) -> String? {
        switch message.body {
        case .plain(let text): return text
        case .html(let html): return stripHTML(html)
        case nil: return message.snippet.isEmpty ? nil : message.snippet
        }
    }

    static func stripHTML(_ html: String) -> String {
        // Remove style/script blocks first, then all remaining tags
        var s = html
        for pattern in ["<style[^>]*>[\\s\\S]*?</style>", "<script[^>]*>[\\s\\S]*?</script>"] {
            s = s.replacingOccurrences(of: pattern, with: " ", options: [.regularExpression, .caseInsensitive])
        }
        s = s.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        return s
            .replacingOccurrences(of: "&nbsp;",  with: " ")
            .replacingOccurrences(of: "&amp;",   with: "&")
            .replacingOccurrences(of: "&lt;",    with: "<")
            .replacingOccurrences(of: "&gt;",    with: ">")
            .replacingOccurrences(of: "&quot;",  with: "\"")
            .replacingOccurrences(of: "&#39;",   with: "'")
    }
}
