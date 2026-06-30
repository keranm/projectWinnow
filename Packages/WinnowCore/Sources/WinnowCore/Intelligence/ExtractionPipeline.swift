import Foundation

/// Routes threads through intelligence extraction tiers.
/// Tier 1 (this file) is deterministic regex — runs synchronously, zero latency.
/// Tier 2 (Core ML / NLEmbedding) and Tier 3 (Foundation Models) are async and off by default.
public actor ExtractionPipeline {
    public static let shared = ExtractionPipeline()
    private init() {}

    /// Runs Tier 1 extractors over a batch of threads and returns annotated copies.
    public func processTier1(_ threads: [MailThread]) -> [MailThread] {
        threads.map { annotate($0) }
    }

    private func annotate(_ thread: MailThread) -> MailThread {
        var t = thread
        var results: [IntelligenceResult] = []

        if let pkg = PackageExtractor.extract(from: t) {
            results.append(.packageTracking(pkg))
        }
        if results.isEmpty, let flight = FlightExtractor.extract(from: t) {
            results.append(.flightInfo(flight))
        }
        if results.isEmpty, let bill = BillExtractor.extract(from: t) {
            results.append(.bill(bill))
        }

        t.intelligenceResults = results
        return t
    }
}
