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

    /// Runs the Tier 1 summary extractor for a single thread, on demand (user-triggered, not part of batch sync).
    public func summarize(_ thread: MailThread) -> MailThread {
        var t = thread
        if let summary = SummaryExtractor.extract(from: t) {
            t.summary = summary
        }
        return t
    }

    /// Re-runs calendar event extraction against a full message body, filling in fields
    /// (location, guests, meeting link) that aren't available at metadata-only sync time.
    /// No-op if the thread has no `.calendarEvent` result yet.
    public func enrichCalendarEvent(_ thread: MailThread) -> MailThread {
        var t = thread
        guard let idx = t.intelligenceResults.firstIndex(where: { if case .calendarEvent = $0 { return true }; return false }),
              case .calendarEvent(let info) = t.intelligenceResults[idx],
              let body = t.messages.last?.body
        else { return t }
        t.intelligenceResults[idx] = .calendarEvent(CalendarEventExtractor.enrich(info, withBody: body))
        return t
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
        if results.isEmpty, let event = CalendarEventExtractor.extract(from: t) {
            results.append(.calendarEvent(event))
        }
        if results.isEmpty, let bill = BillExtractor.extract(from: t) {
            results.append(.bill(bill))
        }

        t.intelligenceResults = results
        return t
    }
}
