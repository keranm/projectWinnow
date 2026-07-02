import Foundation
import Testing
@testable import WinnowCore

@Suite("InboxTriage")
struct InboxTriageTests {

    private static let selfEmail = "keran@gmail.com"
    private static let now = Date(timeIntervalSince1970: 1_780_000_000)

    private func message(
        id: String, from: String, to: [String] = [selfEmail],
        subject: String = "Subject", snippet: String = "", offset: TimeInterval = 0
    ) -> MailMessage {
        MailMessage(
            id: id, threadID: "t1", accountID: "a1",
            from: Participant(email: from),
            to: to.map { Participant(email: $0) },
            subject: subject, snippet: snippet,
            date: Self.now.addingTimeInterval(offset)
        )
    }

    private func thread(_ messages: [MailMessage], results: [IntelligenceResult] = []) -> MailThread {
        MailThread(
            id: "t1", accountID: "a1",
            subject: messages.first?.subject ?? "", snippet: messages.last?.snippet ?? "",
            messages: messages, lastMessageDate: messages.last?.date ?? Self.now,
            intelligenceResults: results
        )
    }

    private func important(_ t: MailThread, correspondents: Set<String> = []) -> Bool {
        InboxTriage.isImportant(t, selfEmail: Self.selfEmail, correspondents: correspondents, now: Self.now)
    }

    // MARK: - Not important

    @Test("in-transit shipment notification is not important")
    func shipmentNotification() {
        let pkg = IntelligenceResult.packageTracking(.init(
            carrier: "AliExpress", trackingNumber: "8213", status: .inTransit
        ))
        let t = thread([message(id: "m1", from: "transaction@notice.aliexpress.com",
                                subject: "Order 8213: order shipped", snippet: "Track your order")],
                       results: [pkg])
        #expect(!important(t))
    }

    @Test("generic business update from an unknown sender is not important")
    func businessUpdate() {
        let t = thread([message(id: "m1", from: "hello@amber.com.au",
                                subject: "You can now add or remove GreenPower in the app",
                                snippet: "You can now add or remove GreenPower.")])
        #expect(!important(t))
    }

    @Test("unknown human sender with informational mail is not important")
    func unknownInformational() {
        let t = thread([message(id: "m1", from: "dana@acme.io",
                                snippet: "FYI the office is closed Monday.")])
        #expect(!important(t))
    }

    // MARK: - Important

    @Test("mail from a known correspondent is important")
    func knownCorrespondent() {
        let t = thread([message(id: "m1", from: "dana@acme.io",
                                snippet: "FYI the office is closed Monday.")])
        #expect(important(t, correspondents: ["dana@acme.io"]))
    }

    @Test("a question from a stranger is important (needs a reply)")
    func strangerQuestion() {
        let t = thread([message(id: "m1", from: "newclient@startup.co",
                                snippet: "Are you taking on new projects this quarter?")])
        #expect(important(t))
    }

    @Test("out-for-delivery package is important right now")
    func outForDelivery() {
        let pkg = IntelligenceResult.packageTracking(.init(
            carrier: "AusPost", trackingNumber: "0080", status: .outForDelivery
        ))
        let t = thread([message(id: "m1", from: "noreply@auspost.com.au")], results: [pkg])
        #expect(important(t))
    }

    @Test("package with a same-morning ETA is important; next-week is not")
    func packageETA() {
        func t(_ eta: Date) -> MailThread {
            thread([message(id: "m1", from: "noreply@auspost.com.au")],
                   results: [.packageTracking(.init(carrier: "AusPost", trackingNumber: "0080",
                                                    status: .inTransit, estimatedDelivery: eta))])
        }
        #expect(important(t(Self.now.addingTimeInterval(3600))))
        #expect(!important(t(Self.now.addingTimeInterval(5 * 86_400))))
    }

    @Test("flight departing tomorrow morning is important; next month is not")
    func flightDeparture() {
        func t(_ dep: Date) -> MailThread {
            thread([message(id: "m1", from: "noreply@qantas.com.au")],
                   results: [.flightInfo(.init(flightNumber: "QF81", from: "SYD", to: "SIN", departureDate: dep))])
        }
        #expect(important(t(Self.now.addingTimeInterval(20 * 3600))))
        #expect(!important(t(Self.now.addingTimeInterval(30 * 86_400))))
    }

    @Test("personal tone promotes an unknown sender; marketing tone does not")
    func tonePromoter() {
        var personal = thread([message(id: "m1", from: "dana@acme.io",
                                       snippet: "Great meeting you at the conference last week.")])
        personal.senderTone = .personal
        #expect(important(personal))

        var marketing = thread([message(id: "m2", from: "hello@amber.com.au",
                                        snippet: "You can now add or remove GreenPower.")])
        marketing.senderTone = .marketing
        #expect(!important(marketing))
    }

    @Test("sent-header addresses parse names, brackets and bare emails")
    func headerParsing() {
        let parsed = GmailAPIClient.emails(inHeader: #"Dana Whitfield <dana@acme.io>, bob@y.org, "Nair, Priya" <priya@acme.io>"#)
        #expect(Set(parsed) == ["dana@acme.io", "bob@y.org", "priya@acme.io"])
    }

    // MARK: - Correspondents

    @Test("correspondents come from threads you took part in")
    func correspondentExtraction() {
        let conversation = thread([
            message(id: "m1", from: "marco@acme.io", offset: 0),
            message(id: "m2", from: Self.selfEmail, to: ["marco@acme.io", "priya@acme.io"], offset: 60),
        ])
        let oneWay = thread([message(id: "m3", from: "hello@amber.com.au")])

        let people = InboxTriage.correspondents(in: [conversation, oneWay], selfEmail: Self.selfEmail)
        #expect(people == ["marco@acme.io", "priya@acme.io"])
    }
}
