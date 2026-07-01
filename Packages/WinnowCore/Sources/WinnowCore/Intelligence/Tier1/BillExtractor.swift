import Foundation

enum BillExtractor {

    // These signal an already-paid transaction — exclude immediately.
    private static let receiptSignals = [
        "your receipt", "receipt from", "receipt for", "purchase receipt", "sales receipt",
        "order confirmation", "order summary", "purchase confirmation",
        "payment received", "payment successful", "payment confirmed", "payment complete",
        "paid successfully", "successfully paid", "successfully charged",
        "thank you for your purchase", "thank you for your order", "thank you for purchasing",
        "you've purchased", "you have purchased", "successfully purchased",
        "your order has shipped", "your order is on its way",
        "apple receipt", "apple purchase", "app store receipt",
        "itunes receipt", "google play receipt",
    ]

    // These signal an upcoming or recurring obligation — keep.
    private static let billSignals = [
        "invoice",        // actual invoice (B2B or utility)
        "payment due",    // explicit due-date wording
        "amount due",
        "balance due",
        "your bill",      // "your bill is ready"
        "billing statement",
        "account statement",
        "statement ready",
        "plan renewal",   // subscription renewal notices
        "subscription renewal",
        "subscription fee",
        "membership renewal",
        "membership fee",
        "annual renewal",
        "annual fee",
        "monthly fee",
        "auto-renew",
        "auto renew",
        "upcoming charge",
        "upcoming renewal",
        "next payment",
    ]

    // Subscription-specific signals (used to set isSubscription flag)
    private static let subscriptionSignals = [
        "subscription", "renewal", "membership", "annual fee", "monthly fee",
        "auto-renew", "auto renew", "plan renewal", "recurring",
    ]

    private static let amountPattern = #"(?:[$£€]|USD|GBP|EUR|AUD)\s*(\d+(?:[.,]\d{1,2})?)"#

    static func extract(from thread: MailThread) -> IntelligenceResult.BillInfo? {
        let combined = [thread.subject, thread.snippet].joined(separator: " ")
        let lower = combined.lowercased()

        // Hard exclude receipts / confirmations of already-paid transactions
        if receiptSignals.contains(where: { lower.contains($0) }) { return nil }

        // Must match at least one bill signal to proceed
        guard billSignals.contains(where: { lower.contains($0) }) else { return nil }

        let (amount, currency) = extractAmount(from: combined)
        let merchant = thread.messages.last?.from.displayName ?? thread.messages.last?.from.email ?? "Unknown"

        return IntelligenceResult.BillInfo(
            merchant: merchant,
            amount: amount ?? 0,
            currency: currency ?? "USD"
        )
    }

    private static func extractAmount(from text: String) -> (Double?, String?) {
        guard let regex = try? NSRegularExpression(pattern: amountPattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))
        else { return (nil, nil) }

        let full   = (text as NSString).substring(with: match.range)
        let digits = (text as NSString).substring(with: match.range(at: 1))
            .replacingOccurrences(of: ",", with: ".")
        let amount = Double(digits)

        let currency: String
        if full.hasPrefix("$")                        { currency = "USD" }
        else if full.hasPrefix("£")                   { currency = "GBP" }
        else if full.hasPrefix("€")                   { currency = "EUR" }
        else if full.uppercased().hasPrefix("AUD")    { currency = "AUD" }
        else if full.uppercased().hasPrefix("GBP")    { currency = "GBP" }
        else if full.uppercased().hasPrefix("EUR")    { currency = "EUR" }
        else                                           { currency = "USD" }

        return (amount, currency)
    }
}
