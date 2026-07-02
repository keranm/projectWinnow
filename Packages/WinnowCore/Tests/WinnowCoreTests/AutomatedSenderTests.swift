import Foundation
import Testing
@testable import WinnowCore

@Suite("MailThread.isLikelyAutomated")
struct AutomatedSenderTests {

    private func thread(
        fromEmail: String,
        results: [IntelligenceResult] = []
    ) -> MailThread {
        let date = Date(timeIntervalSince1970: 1_780_000_000)
        let message = MailMessage(
            id: "m1", threadID: "t1", accountID: "a1",
            from: Participant(name: nil, email: fromEmail),
            to: [Participant(email: "alex@morgan.studio")],
            subject: "Subject", snippet: "Snippet", date: date
        )
        return MailThread(
            id: "t1", accountID: "a1", subject: "Subject", snippet: "Snippet",
            messages: [message], lastMessageDate: date, intelligenceResults: results
        )
    }

    @Test("transactional and no-reply senders are automated", arguments: [
        "no-reply@accounts.example.com",
        "noreply@github.com",
        "transaction@notice.aliexpress.com",
        "orders-eu@amazon.de",
        "noreply+billing@stripe.com",
        "notifications@linkedin.com",
        "mailer-daemon@googlemail.com",
        "hello@email.substack.com",
    ])
    func automatedSenders(email: String) {
        #expect(thread(fromEmail: email).isLikelyAutomated)
    }

    @Test("human senders are not automated", arguments: [
        "marco@acme.io",
        "dana.whitfield@gmail.com",
        "newsome@lawfirm.com",       // starts with "news" but is a surname
        "ordonez@startup.co",        // starts with "ord…" but not "order"
        "alerton@consulting.com",    // starts with "alert" + letter
    ])
    func humanSenders(email: String) {
        #expect(!thread(fromEmail: email).isLikelyAutomated)
    }

    @Test("any Tier 1 extraction marks the thread automated")
    func extractionMeansAutomated() {
        let pkg = IntelligenceResult.packageTracking(.init(
            carrier: "AliExpress", trackingNumber: "821314015638", status: .inTransit
        ))
        let t = thread(fromEmail: "friendly.human@gmail.com", results: [pkg])
        #expect(t.isLikelyAutomated)
    }

    @Test("empty thread is not automated")
    func emptyThread() {
        var t = thread(fromEmail: "x@y.z")
        t.messages = []
        #expect(!t.isLikelyAutomated)
    }
}
