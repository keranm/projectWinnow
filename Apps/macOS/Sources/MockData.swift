import Foundation
import WinnowCore

enum MockData {
    static let accounts: [Account] = [
        Account(id: "acc1", email: "keran@gmail.com", displayName: "Keran McKenzie", provider: .gmail, color: .blue)
    ]

    static let threads: [MailThread] = [
        // Needs a reply — hero thread for Today view
        MailThread(
            id: "t1",
            accountID: "acc1",
            subject: "Re: Q3 launch — is Thursday still good?",
            snippet: "Just checking in on the timeline. Can we sync Thursday morning before the all-hands?",
            messages: [
                MailMessage(
                    id: "m1a",
                    threadID: "t1",
                    accountID: "acc1",
                    from: Participant(name: "Keran McKenzie", email: "keran@gmail.com"),
                    to: [Participant(name: "Sarah Chen", email: "sarah@acme.io")],
                    subject: "Q3 launch — is Thursday still good?",
                    snippet: "Hey Sarah, can we lock in Thursday for the Q3 review?",
                    date: Date().addingTimeInterval(-86400 * 3)
                ),
                MailMessage(
                    id: "m1b",
                    threadID: "t1",
                    accountID: "acc1",
                    from: Participant(name: "Sarah Chen", email: "sarah@acme.io"),
                    to: [Participant(name: "Keran McKenzie", email: "keran@gmail.com")],
                    subject: "Re: Q3 launch — is Thursday still good?",
                    snippet: "Just checking in on the timeline. Can we sync Thursday morning before the all-hands?",
                    body: .plain("Hi Keran,\n\nJust checking in on the timeline — the design review went well and I think we're in good shape.\n\nCan we sync Thursday morning before the all-hands? I want to walk you through the updated launch deck before we present it to the wider team.\n\nBest,\nSarah"),
                    date: Date().addingTimeInterval(-3600 * 4),
                    isRead: false
                )
            ],
            labels: ["INBOX", "IMPORTANT"],
            isRead: false,
            lastMessageDate: Date().addingTimeInterval(-3600 * 4),
            needsReply: true,
            hasDraftReady: true,
            summary: "Sarah confirmed the design review went well and wants to sync Thursday morning before the all-hands to walk through the updated launch deck.",
            suggestedReplies: ["Thursday morning works great", "Can we do 10am?", "Let's find a different time"]
        ),

        // Package tracking
        MailThread(
            id: "t2",
            accountID: "acc1",
            subject: "Your MacBook Pro is out for delivery",
            snippet: "Your package will arrive today by 8pm. Track: 1Z999AA10123456784",
            messages: [
                MailMessage(
                    id: "m2",
                    threadID: "t2",
                    accountID: "acc1",
                    from: Participant(name: "Apple Store", email: "no-reply@apple.com"),
                    to: [Participant(name: "Keran McKenzie", email: "keran@gmail.com")],
                    subject: "Your MacBook Pro is out for delivery",
                    snippet: "Your package will arrive today by 8pm.",
                    body: .plain("Good news — your MacBook Pro 14\" M4 Pro is out for delivery and should arrive by 8pm today.\n\nTracking: 1Z999AA10123456784\nCarrier: UPS\n\nApple Store"),
                    date: Date().addingTimeInterval(-3600 * 2),
                    isRead: true
                )
            ],
            labels: ["INBOX"],
            isRead: true,
            lastMessageDate: Date().addingTimeInterval(-3600 * 2),
            intelligenceResults: [
                .packageTracking(.init(
                    carrier: "UPS",
                    trackingNumber: "1Z999AA10123456784",
                    status: .outForDelivery,
                    estimatedDelivery: Calendar.current.startOfDay(for: Date()).addingTimeInterval(3600 * 20)
                ))
            ]
        ),

        // Flight
        MailThread(
            id: "t3",
            accountID: "acc1",
            subject: "Flight confirmed: LHR → JFK on 14 Jul",
            snippet: "Your booking is confirmed. BA178, departing 11:30. Booking ref: WN4KR2",
            messages: [
                MailMessage(
                    id: "m3",
                    threadID: "t3",
                    accountID: "acc1",
                    from: Participant(name: "British Airways", email: "ba@updates.britishairways.com"),
                    to: [Participant(name: "Keran McKenzie", email: "keran@gmail.com")],
                    subject: "Flight confirmed: LHR → JFK on 14 Jul",
                    snippet: "Your booking is confirmed. BA178, departing 11:30.",
                    body: .plain("Your booking is confirmed.\n\nFlight: BA178\nLondon Heathrow (LHR) → New York JFK\nDate: 14 July 2026, 11:30\nClass: Economy\nBooking ref: WN4KR2\n\nPlease check in online from 24 hours before departure.\n\nBritish Airways"),
                    date: Date().addingTimeInterval(-86400 * 5),
                    isRead: true
                )
            ],
            labels: ["INBOX"],
            isRead: true,
            lastMessageDate: Date().addingTimeInterval(-86400 * 5),
            intelligenceResults: [
                .flightInfo(.init(
                    flightNumber: "BA178",
                    from: "LHR",
                    to: "JFK",
                    departureDate: Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 14, hour: 11, minute: 30))!,
                    gate: nil
                ))
            ]
        ),

        // Calendar invite
        MailThread(
            id: "t4",
            accountID: "acc1",
            subject: "Invite: Product strategy sync · Thu 3pm",
            snippet: "Tom Walsh has invited you to Product strategy sync on Thursday at 3:00pm",
            messages: [
                MailMessage(
                    id: "m4",
                    threadID: "t4",
                    accountID: "acc1",
                    from: Participant(name: "Tom Walsh", email: "tom@acme.io"),
                    to: [Participant(name: "Keran McKenzie", email: "keran@gmail.com")],
                    subject: "Invite: Product strategy sync · Thu 3pm",
                    snippet: "Tom Walsh has invited you to Product strategy sync on Thursday at 3:00pm",
                    date: Date().addingTimeInterval(-3600 * 6),
                    isRead: false
                )
            ],
            labels: ["INBOX", "IMPORTANT"],
            isRead: false,
            lastMessageDate: Date().addingTimeInterval(-3600 * 6),
            needsReply: true,
            summary: "Tom Walsh has invited you to a product strategy sync this Thursday at 3pm. No conflicts found in your calendar.",
            suggestedReplies: ["Accept", "Maybe — I'll check", "Decline"],
            intelligenceResults: [
                .calendarEvent(.init(
                    title: "Product strategy sync",
                    startDate: Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 15, weekday: 5), matchingPolicy: .nextTime)!,
                    location: "Google Meet",
                    organiser: "Tom Walsh",
                    organiserEmail: "tom@acme.io"
                ))
            ]
        ),

        // Bill / subscription
        MailThread(
            id: "t5",
            accountID: "acc1",
            subject: "Your Notion subscription renews in 3 days — £16/mo",
            snippet: "Your Plus plan renews on 3 July. Note: price increased from £13/mo.",
            messages: [
                MailMessage(
                    id: "m5",
                    threadID: "t5",
                    accountID: "acc1",
                    from: Participant(name: "Notion", email: "billing@notion.so"),
                    to: [Participant(name: "Keran McKenzie", email: "keran@gmail.com")],
                    subject: "Your Notion subscription renews in 3 days",
                    snippet: "Your Plus plan renews on 3 July. Note: price increased from £13/mo.",
                    date: Date().addingTimeInterval(-3600 * 1),
                    isRead: false
                )
            ],
            labels: ["INBOX"],
            isRead: false,
            lastMessageDate: Date().addingTimeInterval(-3600 * 1),
            intelligenceResults: [
                .bill(.init(
                    merchant: "Notion",
                    amount: 16.0,
                    currency: "GBP",
                    dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
                    previousAmount: 13.0
                ))
            ]
        ),

        // Newsletter (low importance, no extraction)
        MailThread(
            id: "t6",
            accountID: "acc1",
            subject: "The Pragmatic Engineer #128: Claude's new tool-use API",
            snippet: "This week: a deep look at how Anthropic's tool-use API compares to function calling...",
            messages: [
                MailMessage(
                    id: "m6",
                    threadID: "t6",
                    accountID: "acc1",
                    from: Participant(name: "Pragmatic Engineer", email: "newsletter@pragmaticengineer.com"),
                    to: [Participant(name: "Keran McKenzie", email: "keran@gmail.com")],
                    subject: "The Pragmatic Engineer #128: Claude's new tool-use API",
                    snippet: "This week: a deep look at how Anthropic's tool-use API compares to function calling...",
                    date: Date().addingTimeInterval(-3600 * 8),
                    isRead: true
                )
            ],
            labels: ["INBOX"],
            isRead: true,
            lastMessageDate: Date().addingTimeInterval(-3600 * 8)
        )
    ]
}
