import Foundation

enum FlightExtractor {
    private static let subjectKeywords = [
        "booking confirmation", "e-ticket", "eticket", "itinerary",
        "flight confirmation", "your trip", "travel itinerary",
        "boarding pass", "check-in", "your flight"
    ]

    // IATA flight number: 2–3 letters + 1–4 digits (e.g. QF1, BA178, AA1234)
    private static let flightNumberPattern = #"\b([A-Z]{2,3})\s?(\d{1,4})\b"#

    // Airport code context: "SYD to LHR", "from MEL", "LAX-JFK"
    private static let airportPattern = #"\b([A-Z]{3})\s*(?:to|-|→|>)\s*([A-Z]{3})\b"#

    // Known airline IATA codes (subset)
    private static let knownAirlines: Set<String> = [
        "QF","VA","JQ","TT","QR","EK","SQ","CX","BA","AA","UA","DL","LH","AF",
        "KL","EY","TK","MH","GA","AI","NZ","WS","AC","WN","FR","U2","VY","IB"
    ]

    static func extract(from thread: MailThread) -> IntelligenceResult.FlightInfo? {
        let combined = [thread.subject, thread.snippet].joined(separator: " ")
        let lower = combined.lowercased()

        guard subjectKeywords.contains(where: { lower.contains($0) }) else { return nil }

        let flightNumber = extractFlightNumber(from: combined)
        let (origin, destination) = extractAirports(from: combined)

        guard flightNumber != nil || (origin != nil && destination != nil) else { return nil }

        return IntelligenceResult.FlightInfo(
            flightNumber: flightNumber ?? "—",
            from: origin ?? "—",
            to: destination ?? "—",
            departureDate: thread.lastMessageDate  // best guess until body parsing
        )
    }

    private static func extractFlightNumber(from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: flightNumberPattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))
        else { return nil }
        let airline = (text as NSString).substring(with: match.range(at: 1))
        let number  = (text as NSString).substring(with: match.range(at: 2))
        guard knownAirlines.contains(airline) else { return nil }
        return "\(airline)\(number)"
    }

    private static func extractAirports(from text: String) -> (String?, String?) {
        guard let regex = try? NSRegularExpression(pattern: airportPattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))
        else { return (nil, nil) }
        let from = (text as NSString).substring(with: match.range(at: 1))
        let to   = (text as NSString).substring(with: match.range(at: 2))
        return (from, to)
    }
}
