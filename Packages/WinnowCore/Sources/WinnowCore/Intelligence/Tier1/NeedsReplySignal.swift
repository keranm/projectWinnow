import Foundation

/// Deterministic needs-reply detection — replaces the Gmail-IMPORTANT proxy.
///
/// A thread needs a reply only when all of these hold:
///   1. the last message is inbound (you didn't speak last),
///   2. it isn't automated mail (`isLikelyAutomated`),
///   3. you're part of the conversation (a message from you exists in the thread),
///      OR the latest message plainly asks for a response.
///
/// The participation gate is what kills "nice to know" mail: ToS updates, receipts,
/// council auto-acknowledgements and security notices are one-way — you never wrote
/// into those threads and they don't ask you anything.
public enum NeedsReplySignal {

    public static func needsReply(_ thread: MailThread, selfEmail: String?) -> Bool {
        guard let last = thread.messages.last else { return false }
        let selfLower = selfEmail?.lowercased()

        guard last.from.email.lowercased() != selfLower else { return false }
        if thread.needsReply { return true }   // explicit upstream flag (tests, future Tier 2)

        // Participation outranks the automated heuristics: a thread you wrote into where
        // someone answered is a live conversation, whatever words appear in it.
        let participated = selfLower.map { se in
            thread.messages.contains { $0.from.email.lowercased() == se }
        } ?? false
        if participated { return true }

        guard !thread.isLikelyAutomated else { return false }
        return asksForResponse(in: last)
    }

    /// Does the message read like it expects an answer? Questions and direct requests.
    static func asksForResponse(in message: MailMessage) -> Bool {
        let raw = TextSanitizer.plainText(for: message) ?? message.snippet
        let text = String(raw.prefix(1200)).lowercased()
        if text.contains("?") { return true }
        let requestPhrases = [
            "let me know", "can you", "could you", "would you", "please confirm",
            "please review", "please send", "please reply", "please respond",
            "get back to me", "your thoughts", "what do you think", "rsvp",
            "confirm receipt", "awaiting your", "await your", "looking forward to hearing",
        ]
        return requestPhrases.contains { text.contains($0) }
    }
}
