import Foundation

enum BillExtractor {
    private static let subjectKeywords = [
        "invoice", "receipt", "subscription", "renewal", "payment due",
        "your bill", "statement", "charged", "billing", "plan renewal",
        "membership", "annual fee", "monthly fee", "auto-renew", "auto renew"
    ]

    // Currency amount: $12.99, £9, €144, AUD 49.00
    private static let amountPattern = #"(?:[$£€]|USD|GBP|EUR|AUD)\s*(\d+(?:[.,]\d{1,2})?)"#
    private static let currencySymbols: [String: String] = [
        "$": "USD", "£": "GBP", "€": "EUR", "USD": "USD", "GBP": "GBP", "EUR": "EUR", "AUD": "AUD"
    ]

    static func extract(from thread: MailThread) -> IntelligenceResult.BillInfo? {
        let combined = [thread.subject, thread.snippet].joined(separator: " ")
        let lower = combined.lowercased()

        guard subjectKeywords.contains(where: { lower.contains($0) }) else { return nil }

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
        if full.hasPrefix("$")      { currency = "USD" }
        else if full.hasPrefix("£") { currency = "GBP" }
        else if full.hasPrefix("€") { currency = "EUR" }
        else if full.uppercased().hasPrefix("AUD") { currency = "AUD" }
        else if full.uppercased().hasPrefix("GBP") { currency = "GBP" }
        else if full.uppercased().hasPrefix("EUR") { currency = "EUR" }
        else                         { currency = "USD" }

        return (amount, currency)
    }
}
