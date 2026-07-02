import Foundation
import NaturalLanguage

/// How a message reads — who sent it is `isLikelyAutomated`'s job; this is about tone.
public enum SenderTone: String, Sendable, Codable {
    case personal       // written by a person, to you
    case transactional  // receipts, confirmations, account notices
    case marketing      // promotions, product updates, newsletters
}

/// Tier 2 — on-device tone classification via NLEmbedding sentence embeddings
/// (Apple NaturalLanguage; nothing leaves the device, no model download).
///
/// Zero-shot prototype matching: the subject + preview is embedded and compared
/// against small prototype sets per tone; the nearest tone wins only when it's a
/// clear winner. Returns nil when unsure — callers must treat nil as "no signal".
/// In triage this acts as a promoter only: it can lift personal-sounding mail from
/// unknown senders into Important, it never demotes a deterministic decision.
public actor ToneClassifier {
    public static let shared = ToneClassifier()
    private let embedding = NLEmbedding.sentenceEmbedding(for: .english)
    private init() {}

    public var isAvailable: Bool { embedding != nil }

    /// Loads the embedding model (the slow part) ahead of first classification —
    /// call early in app startup, off the sync path.
    public func prewarm() {
        _ = embedding?.vector(for: "hello")
    }

    public func tone(subject: String, preview: String) -> SenderTone? {
        guard let embedding else { return nil }
        let text = String("\(subject). \(preview)".prefix(300)).lowercased()

        var nearest: [(tone: SenderTone, distance: Double)] = []
        for (tone, examples) in Self.prototypes {
            let d = examples
                .map { embedding.distance(between: text, and: $0, distanceType: .cosine) }
                .min() ?? .infinity
            nearest.append((tone, d))
        }
        nearest.sort { $0.distance < $1.distance }

        guard let best = nearest.first, nearest.count > 1 else { return nil }
        let runnerUp = nearest[1].distance
        // Close enough to a prototype, and clearly closer than the next tone.
        guard best.distance < 1.05, runnerUp - best.distance > 0.02 else { return nil }
        return best.tone
    }

    private static let prototypes: [SenderTone: [String]] = [
        .personal: [
            "hey, are you free for lunch this week?",
            "thanks so much for yesterday, really appreciate it.",
            "can you take a look at this and tell me what you think?",
            "quick question about the project — do you have a minute?",
            "sounds good, see you then!",
            "hope you're well — would love to catch up soon.",
            "here's the draft we discussed, keen to hear your thoughts.",
        ],
        .transactional: [
            "your order has shipped and is on its way.",
            "your verification code is 123456.",
            "your invoice for this month is attached.",
            "your appointment has been confirmed.",
            "your password was changed successfully.",
            "receipt for your recent purchase.",
            "thank you for contacting us, your request has been received.",
        ],
        .marketing: [
            "don't miss our biggest sale of the year!",
            "new features you'll love in our latest update.",
            "you can now do even more with our app.",
            "subscribe now and save 20% on your first order.",
            "introducing our newest product line.",
            "your weekly digest: top stories this week.",
            "we've made some exciting changes to our service.",
        ],
    ]
}
