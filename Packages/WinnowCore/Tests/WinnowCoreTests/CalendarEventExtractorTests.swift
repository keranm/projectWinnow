import Foundation
import Testing
@testable import WinnowCore

@Suite("CalendarEventExtractor")
struct CalendarEventExtractorTests {

    // MARK: - Helpers

    private static let messageDate = Date(timeIntervalSince1970: 1_780_000_000)

    private func thread(
        subject: String,
        fromName: String? = "Dana Whitfield",
        fromEmail: String = "dana@acme.io",
        body: MessageBody? = nil
    ) -> MailThread {
        let message = MailMessage(
            id: "m1",
            threadID: "t1",
            accountID: "a1",
            from: Participant(name: fromName, email: fromEmail),
            to: [Participant(email: "alex@morgan.studio")],
            subject: subject,
            snippet: "",
            body: body,
            date: Self.messageDate
        )
        return MailThread(
            id: "t1",
            accountID: "a1",
            subject: subject,
            snippet: "",
            messages: [message],
            lastMessageDate: Self.messageDate
        )
    }

    // MARK: - Detection

    @Test("standard Invitation subject is detected")
    func standardInvitation() throws {
        let t = thread(subject: "Invitation: Q3 hero review @ Fri Jul 11, 2026 12pm - 1pm (AEST)")
        let info = try #require(CalendarEventExtractor.extract(from: t))
        #expect(info.title == "Q3 hero review")
        #expect(info.organiser == "Dana Whitfield")
        #expect(info.organiserEmail == "dana@acme.io")
        #expect(!info.isCancelled)
    }

    @Test("Updated invitation prefix is detected and stripped")
    func updatedInvitation() throws {
        let t = thread(subject: "Updated invitation: Q3 hero review @ Fri Jul 11, 2026 12pm - 1pm (AEST)")
        let info = try #require(CalendarEventExtractor.extract(from: t))
        #expect(info.title == "Q3 hero review")
        #expect(!info.isCancelled)
    }

    @Test("cancelled events are flagged, both spellings", arguments: [
        "Canceled event: Q3 hero review @ Fri Jul 11, 2026 12pm (AEST)",
        "Cancelled event: Q3 hero review @ Fri Jul 11, 2026 12pm (AEST)",
    ])
    func cancelledEvent(subject: String) throws {
        let info = try #require(CalendarEventExtractor.extract(from: thread(subject: subject)))
        #expect(info.title == "Q3 hero review")
        #expect(info.isCancelled)
    }

    @Test("ordinary email is not detected")
    func ordinaryEmail() {
        let t = thread(subject: "Re: Contract redlines")
        #expect(CalendarEventExtractor.extract(from: t) == nil)
    }

    @Test("subject mentioning 'Invitation' mid-string is not detected")
    func invitationMidSubject() {
        let t = thread(subject: "Your Invitation: party planning doc")
        #expect(CalendarEventExtractor.extract(from: t) == nil)
    }

    @Test("calendar sender domain is detected without a known prefix")
    func inviteSenderDomain() throws {
        let t = thread(
            subject: "Q3 hero review @ Fri Jul 11, 2026 12pm (AEST)",
            fromEmail: "dana@acme.io.calendar.google.com"
        )
        let info = try #require(CalendarEventExtractor.extract(from: t))
        #expect(info.title == "Q3 hero review")
    }

    @Test("thread with no messages is not detected")
    func emptyThread() {
        var t = thread(subject: "Invitation: Standup @ Fri Jul 11, 2026 9am")
        t.messages = []
        #expect(CalendarEventExtractor.extract(from: t) == nil)
    }

    // MARK: - Title / when parsing

    @Test("title containing @ survives — split happens on the last ' @ '")
    func titleWithAtSign(){
        let t = thread(subject: "Invitation: Coffee @ Blue Bottle @ Fri Jul 11, 2026 9am (AEST)")
        let info = CalendarEventExtractor.extract(from: t)
        #expect(info?.title == "Coffee @ Blue Bottle")
    }

    @Test("date and time are parsed from the when segment")
    func dateParsing() throws {
        let t = thread(subject: "Invitation: Q3 hero review @ Fri Jul 11, 2026 12:00pm (AEST)")
        let info = try #require(CalendarEventExtractor.extract(from: t))
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: info.startDate)
        #expect(parts.year == 2026)
        #expect(parts.month == 7)
        #expect(parts.day == 11)
        #expect(parts.hour == 12)
        #expect(parts.minute == 0)
    }

    @Test("time range yields an end date after the start")
    func timeRange() throws {
        let t = thread(subject: "Invitation: Q3 hero review @ Fri Jul 11, 2026 12pm - 1pm (AEST)")
        let info = try #require(CalendarEventExtractor.extract(from: t))
        let end = try #require(info.endDate)
        #expect(end > info.startDate)
        #expect(end.timeIntervalSince(info.startDate) == 3600)
    }

    @Test("subject without a parseable date falls back to the message date")
    func dateFallback() throws {
        let t = thread(subject: "Invitation: Team sync")
        let info = try #require(CalendarEventExtractor.extract(from: t))
        #expect(info.startDate == Self.messageDate)
        #expect(info.endDate == nil)
    }

    // MARK: - Enrichment from full body

    private let baseInfo = IntelligenceResult.CalendarEventInfo(
        title: "Q3 hero review",
        startDate: messageDate,
        organiser: "Dana Whitfield",
        organiserEmail: "dana@acme.io"
    )

    @Test("plain body yields location, guests, and meeting link")
    func enrichPlainBody() {
        let body = MessageBody.plain("""
        Q3 hero review
        Where: Conference room 4B
        Guests: Dana Whitfield, Alex Morgan, Priya Nair
        Join: https://meet.google.com/q3-hero
        """)
        let info = CalendarEventExtractor.enrich(baseInfo, withBody: body)
        #expect(info.location == "Conference room 4B")
        #expect(info.guests == ["Dana Whitfield", "Alex Morgan", "Priya Nair"])
        #expect(info.meetingLink == "https://meet.google.com/q3-hero")
    }

    @Test("HTML body is stripped before parsing")
    func enrichHTMLBody() {
        let body = MessageBody.html(
            "<div><b>Where:</b> Google Meet</div><div>Guests: Dana Whitfield &middot; Alex Morgan</div>" +
            "<a href=\"x\">https://meet.google.com/q3-hero</a>"
        )
        let info = CalendarEventExtractor.enrich(baseInfo, withBody: body)
        #expect(info.location == "Google Meet")
        #expect(info.meetingLink == "https://meet.google.com/q3-hero")
    }

    @Test("guests split on interpuncts as well as commas")
    func enrichGuestsInterpunct() {
        let body = MessageBody.plain("Who: Dana Whitfield · Alex Morgan · Priya Nair")
        let info = CalendarEventExtractor.enrich(baseInfo, withBody: body)
        #expect(info.guests == ["Dana Whitfield", "Alex Morgan", "Priya Nair"])
    }

    @Test("zoom links are recognised when no Meet link exists")
    func enrichZoomLink() {
        let body = MessageBody.plain("Join Zoom Meeting\nhttps://acme.zoom.us/j/123456?pwd=abc")
        let info = CalendarEventExtractor.enrich(baseInfo, withBody: body)
        #expect(info.meetingLink == "https://acme.zoom.us/j/123456?pwd=abc")
    }

    @Test("body with none of the fields leaves the info unchanged")
    func enrichNoFields() {
        let body = MessageBody.plain("Looking forward to it!")
        let info = CalendarEventExtractor.enrich(baseInfo, withBody: body)
        #expect(info.location == nil)
        #expect(info.guests.isEmpty)
        #expect(info.meetingLink == nil)
        #expect(info.title == baseInfo.title)
        #expect(info.startDate == baseInfo.startDate)
        #expect(info.organiser == baseInfo.organiser)
    }

    @Test("enrichment preserves detection-time fields")
    func enrichPreservesFields() {
        let cancelled = IntelligenceResult.CalendarEventInfo(
            title: "Q3 hero review",
            startDate: Self.messageDate,
            endDate: Self.messageDate.addingTimeInterval(3600),
            organiser: "Dana Whitfield",
            organiserEmail: "dana@acme.io",
            isCancelled: true
        )
        let info = CalendarEventExtractor.enrich(cancelled, withBody: .plain("Where: Room 1"))
        #expect(info.isCancelled)
        #expect(info.endDate == cancelled.endDate)
        #expect(info.organiserEmail == "dana@acme.io")
        #expect(info.location == "Room 1")
    }
}
