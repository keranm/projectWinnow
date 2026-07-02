import Foundation

public struct SummaryExtractor {

    public static func extract(from thread: MailThread) -> String? {
        guard let latest = thread.messages.last else { return nil }

        switch latest.body {
        case .plain(let text):
            return firstSentences(text, count: 3)
        case .html(let html):
            return firstSentences(TextSanitizer.stripHTML(html), count: 3)
        case nil:
            // No body loaded yet — join snippets from the last few messages
            let snippets = thread.messages.suffix(3).reversed()
                .compactMap { $0.snippet }
                .filter { !$0.isEmpty }
            return snippets.isEmpty ? nil : snippets.prefix(2).joined(separator: " … ")
        }
    }

    // MARK: - Private

    private static func firstSentences(_ text: String, count: Int) -> String? {
        let cleaned = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard !cleaned.isEmpty else { return nil }

        var sentences: [String] = []
        cleaned.enumerateSubstrings(in: cleaned.startIndex..., options: [.bySentences]) { sub, _, _, stop in
            guard let s = sub?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return }
            sentences.append(s)
            if sentences.count >= count { stop = true }
        }

        let result = sentences.joined(separator: " ")
        return result.isEmpty ? nil : result
    }
}
