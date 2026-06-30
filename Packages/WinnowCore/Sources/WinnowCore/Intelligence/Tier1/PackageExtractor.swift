import Foundation

enum PackageExtractor {
    private static let subjectKeywords = [
        "shipped", "shipping", "your order", "your parcel", "your package",
        "dispatched", "consignment", "tracking", "delivery", "out for delivery",
        "on its way", "picked up", "collected"
    ]

    private static let carrierPatterns: [(pattern: String, name: String)] = [
        ("couriers?\\s*please|cpb", "CouriersPlease"),
        ("australia\\s*post|aust\\s*post|auspost", "Australia Post"),
        ("fedex", "FedEx"),
        ("\\bups\\b", "UPS"),
        ("\\bdhl\\b", "DHL"),
        ("amazon\\s*logistics|amazon\\s*delivery", "Amazon Logistics"),
        ("toll\\s*(group|ipec|priority)?", "Toll"),
        ("startrack", "StarTrack"),
        ("sendle", "Sendle"),
        ("aramex", "Aramex")
    ]

    // Common tracking number patterns
    private static let trackingPatterns = [
        #"CPB[A-Z0-9]{8,14}"#,                       // CouriersPlease
        #"\b[A-Z]{2}\d{9}[A-Z]{2}\b"#,               // Australia Post
        #"\b1Z[A-Z0-9]{16}\b"#,                       // UPS
        #"\b\d{12}\b|\b\d{15}\b"#,                    // FedEx
        #"\b[A-Z]{3}\d{8}[A-Z]{2}\b"#,               // Generic postal
        #"#?[A-Z]{0,3}\d{8,14}"#                      // Generic alphanumeric
    ]

    static func extract(from thread: MailThread) -> IntelligenceResult.PackageInfo? {
        let combined = [thread.subject, thread.snippet]
            .joined(separator: " ")
            .lowercased()

        guard subjectKeywords.contains(where: { combined.contains($0) }) else { return nil }

        let carrier = detectCarrier(in: combined) ?? detectCarrier(in: thread.messages.last?.from.email ?? "") ?? "Courier"
        let tracking = extractTrackingNumber(from: thread.subject + " " + thread.snippet)
        let status = detectStatus(in: combined)

        return IntelligenceResult.PackageInfo(
            carrier: carrier,
            trackingNumber: tracking ?? "",
            status: status
        )
    }

    private static func detectCarrier(in text: String) -> String? {
        for (pattern, name) in carrierPatterns {
            if text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                return name
            }
        }
        return nil
    }

    private static func extractTrackingNumber(from text: String) -> String? {
        for pattern in trackingPatterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                return String(text[range])
            }
        }
        return nil
    }

    private static func detectStatus(in text: String) -> IntelligenceResult.PackageInfo.Status {
        if text.contains("out for delivery") || text.contains("with driver") || text.contains("on its way today") {
            return .outForDelivery
        }
        if text.contains("delivered") || text.contains("left at") || text.contains("signed for") {
            return .delivered
        }
        return .inTransit
    }
}
