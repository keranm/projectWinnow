import Foundation

public extension MailThread {
    /// Heuristic for mail nobody is waiting on a reply to: transactional/notification
    /// senders, or anything Tier 1 already recognised as a package/flight/bill/calendar
    /// notification. Used to keep "needs a reply" (and reply drafting) to human mail
    /// until the Tier 2 classifier lands.
    var isLikelyAutomated: Bool {
        // A recognised extraction means it's a notification by definition — and calendar
        // invites are answered through RSVP, not a written reply.
        if !intelligenceResults.isEmpty { return true }

        guard let sender = messages.last?.from.email.lowercased() else { return false }
        let parts = sender.components(separatedBy: "@")
        let local = parts.first ?? sender
        let domain = parts.count > 1 ? parts[1] : ""

        if Self.automatedLocalParts.contains(where: { matches(local, keyword: $0) }) { return true }
        if Self.automatedSubdomains.contains(where: { domain.hasPrefix($0) }) { return true }
        return false
    }

    private static let automatedLocalParts: [String] = [
        "no-reply", "noreply", "no_reply", "do-not-reply", "donotreply", "do_not_reply",
        "notification", "notifications", "notify", "alert", "alerts",
        "mailer-daemon", "postmaster", "bounce", "bounces",
        "transaction", "transactions", "order", "orders", "shipping", "shipment",
        "tracking", "receipt", "receipts", "billing", "invoice", "invoices",
        "newsletter", "newsletters", "news", "updates", "marketing", "promo", "offers",
    ]

    private static let automatedSubdomains: [String] = [
        "notice.", "notify.", "notification.", "notifications.",
        "alert.", "alerts.", "bounce.", "bounces.", "email.", "newsletter.",
        "marketing.", "transactional.", "updates.",
    ]

    /// True when the local part is the keyword itself or the keyword followed by a
    /// separator/digit ("orders-eu", "noreply+abc") — but not a longer word ("newsome").
    private func matches(_ local: String, keyword: String) -> Bool {
        guard local.hasPrefix(keyword) else { return false }
        guard local.count > keyword.count else { return true }
        return !local[local.index(local.startIndex, offsetBy: keyword.count)].isLetter
    }
}
