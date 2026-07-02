import Foundation
import Testing
@testable import WinnowCore

@Suite("NeedsReplySignal")
struct NeedsReplySignalTests {

    private static let selfEmail = "keran@gmail.com"
    private static let base = Date(timeIntervalSince1970: 1_780_000_000)

    private func message(
        id: String,
        from: String,
        subject: String = "Subject",
        snippet: String = "",
        body: String? = nil,
        offset: TimeInterval = 0
    ) -> MailMessage {
        MailMessage(
            id: id, threadID: "t1", accountID: "a1",
            from: Participant(email: from),
            to: [Participant(email: Self.selfEmail)],
            subject: subject, snippet: snippet,
            body: body.map { .plain($0) },
            date: Self.base.addingTimeInterval(offset)
        )
    }

    private func thread(_ messages: [MailMessage], subject: String? = nil) -> MailThread {
        MailThread(
            id: "t1", accountID: "a1",
            subject: subject ?? messages.first?.subject ?? "",
            snippet: messages.last?.snippet ?? "",
            messages: messages,
            lastMessageDate: messages.last?.date ?? Self.base
        )
    }

    private func needsReply(_ t: MailThread) -> Bool {
        NeedsReplySignal.needsReply(t, selfEmail: Self.selfEmail)
    }

    // MARK: - The screenshot offenders

    @Test("ToS update from a human-looking Google address is filtered")
    func tosUpdate() {
        let t = thread([message(
            id: "m1", from: "googlecommunityteam-noreply@google.com",
            subject: "Learn more about our updated Terms of Service",
            snippet: "Every couple of years, we update our Terms of Service."
        )])
        #expect(!needsReply(t))
    }

    @Test("login verification code is filtered")
    func verificationCode() {
        let t = thread([message(
            id: "m1", from: "account@twitch.tv",
            subject: "Your Twitch Login Verification Code",
            snippet: "083114 - Someone is trying to log in into Twitch with a new device."
        )])
        #expect(!needsReply(t))
    }

    @Test("password reset from a service address is filtered")
    func passwordReset() {
        let t = thread([message(
            id: "m1", from: "service@dreame.tech",
            subject: "Customer account password reset",
            snippet: "Reset your password Follow this link to reset your password."
        )])
        #expect(!needsReply(t))
    }

    @Test("one-way auto-acknowledgement without participation is filtered")
    func councilAck() {
        let t = thread([message(
            id: "m1", from: "council@mountbarker.sa.gov.au",
            subject: "Thank you for reporting a missed bin collection",
            snippet: "Thank you for notifying us of your missed bin collection."
        )])
        #expect(!needsReply(t))
    }

    // MARK: - Real conversations

    @Test("inbound answer in a thread you wrote into needs a reply")
    func activeConversation() {
        let t = thread([
            message(id: "m1", from: Self.selfEmail, snippet: "Our bin was missed on Tuesday.", offset: 0),
            message(id: "m2", from: "council@mountbarker.sa.gov.au",
                    snippet: "Which street was affected and roughly what time?", offset: 60),
        ])
        #expect(needsReply(t))
    }

    @Test("participation outranks automated content keywords")
    func participationBeatsKeywords() {
        let t = thread([
            message(id: "m1", from: Self.selfEmail, snippet: "Draft attached.", offset: 0),
            message(id: "m2", from: "priya@acme.io",
                    snippet: "Can you review the privacy policy section before Friday", offset: 60),
        ])
        #expect(needsReply(t))
    }

    @Test("you spoke last — nothing to reply to")
    func youSpokeLast() {
        let t = thread([
            message(id: "m1", from: "marco@acme.io", snippet: "Lunch Thursday?", offset: 0),
            message(id: "m2", from: Self.selfEmail, snippet: "Thursday works!", offset: 60),
        ])
        #expect(!needsReply(t))
    }

    @Test("a question from a new sender needs a reply")
    func questionFromStranger() {
        let t = thread([message(
            id: "m1", from: "newclient@startup.co",
            snippet: "Hi Keran — are you taking on new projects this quarter?"
        )])
        #expect(needsReply(t))
    }

    @Test("a request phrase without a question mark still counts")
    func requestPhrase() {
        let t = thread([message(
            id: "m1", from: "dana@acme.io",
            body: "Contract attached. Please confirm by Friday and we'll countersign."
        )])
        #expect(needsReply(t))
    }

    @Test("informational mail from a stranger does not need a reply")
    func informationalStranger() {
        let t = thread([message(
            id: "m1", from: "dana@acme.io",
            snippet: "FYI — the office is closed Monday for the public holiday."
        )])
        #expect(!needsReply(t))
    }

    @Test("explicit needsReply flag is honoured")
    func explicitFlag() {
        var t = thread([message(id: "m1", from: "marco@acme.io", snippet: "FYI only.")])
        t.needsReply = true
        #expect(needsReply(t))
    }
}
