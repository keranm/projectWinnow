import SwiftUI
import AppKit
import WinnowCore
import WinnowUI

/// Reading-pane content for a thread carrying a `.calendarEvent` intelligence result —
/// replaces the normal message body with invite details, a free/busy rail read from
/// EventKit, on-device conflict detection, and inline RSVP.
struct CalendarInviteDetailView: View {
    let thread: MailThread
    let event: IntelligenceResult.CalendarEventInfo

    @Environment(AppState.self) private var appState
    @Environment(WinnowSettings.self) private var settings

    @State private var railBlocks: [BusyBlock] = []
    @State private var conflicts: [BusyBlock] = []
    @State private var suggestedSlot: Date?

    private var candidateEnd: Date { event.endDate ?? event.startDate.addingTimeInterval(3600) }
    private var candidateDuration: TimeInterval { candidateEnd.timeIntervalSince(event.startDate) }

    private var rsvp: RSVPResponse? {
        settings.calendarRSVPs[thread.id].flatMap(RSVPResponse.init)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            details.frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.trailing, 26)
                .overlay(alignment: .trailing) { Color.black.opacity(0.05).frame(width: 1) }

            rail.frame(width: 260, alignment: .topLeading)
                .padding(.leading, 22)
        }
        .padding(.horizontal, WinnowSpacing.sectionHWide)
        .padding(.top, 22)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .safeAreaInset(edge: .bottom) { footer }
        .task(id: thread.id) { await loadCalendarData() }
    }

    // MARK: - Details column

    private var details: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                AssistDiamond(size: .small)
                Text(event.isCancelled ? "CANCELLED EVENT" : "CALENDAR INVITATION")
                    .winnowSectionHeader()
            }

            HStack(alignment: .top, spacing: 14) {
                dateBadge
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.winnowText)
                        .tracking(-0.2)
                        .strikethrough(event.isCancelled)
                    Text(dateRangeLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.winnowTextTertiary)
                }
            }
            .padding(.top, 14)

            VStack(alignment: .leading, spacing: 13) {
                if let location = event.location { metaRow("Where", location) }
                if let organiser = event.organiser { metaRow("Organizer", organiser) }
                if !event.guests.isEmpty { metaRow("Guests", event.guests.joined(separator: " · ")) }
            }
            .padding(.top, 22)

            if let conflict = conflicts.first, settings.calendarFlagConflicts, !event.isCancelled {
                CalendarConflictCard(
                    conflictSummary: "This overlaps \(conflict.title) (\(timeLabel(conflict.start))).",
                    suggestedTimeLabel: suggestedSlot.map(timeLabel),
                    onPropose: suggestedSlot != nil ? { propose(suggestedSlot!) } : nil,
                    onKeep: {}
                )
                .padding(.top, 22)
            }

            if !event.isCancelled {
                RSVPBar(selected: rsvp) { respond($0) }
                    .padding(.top, 22)
            }

            Spacer(minLength: 0)
        }
    }

    private var dateBadge: some View {
        let cal = Calendar.current
        let month = event.startDate.formatted(.dateTime.month(.abbreviated)).uppercased()
        let day = cal.component(.day, from: event.startDate)
        return VStack(spacing: 0) {
            Text(month)
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .background(Color(hex: "E0533D"))
            Text("\(day)")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.winnowText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(Color.winnowSurface)
        }
        .frame(width: 48)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.black.opacity(0.10), lineWidth: 1))
    }

    private func metaRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.winnowTextTertiary)
                .frame(width: 64, alignment: .leading)
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.winnowTextSubdued)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Free/busy rail

    private var rail: some View {
        CalendarFreeBusyRail(
            dayLabel: "Your \(event.startDate.formatted(.dateTime.weekday(.wide)))",
            rangeStart: railWindow.0,
            rangeEnd: railWindow.1,
            blocks: railBlockModels
        )
    }

    private var railWindow: (Date, Date) {
        var starts = [event.startDate] + railBlocks.map { $0.start }
        var ends = [candidateEnd] + railBlocks.map { $0.end }
        if let suggestedSlot {
            starts.append(suggestedSlot)
            ends.append(suggestedSlot.addingTimeInterval(candidateDuration))
        }
        let minStart = starts.min() ?? event.startDate
        let maxEnd = ends.max() ?? candidateEnd
        return (minStart.addingTimeInterval(-3600), maxEnd.addingTimeInterval(3600))
    }

    private var railBlockModels: [FreeBusyRailBlock] {
        var blocks: [FreeBusyRailBlock] = railBlocks.map { block in
            let overlapsCandidate = block.start < candidateEnd && block.end > event.startDate
            return FreeBusyRailBlock(
                title: block.title,
                start: block.start,
                end: block.end,
                style: overlapsCandidate ? .conflict : .busy
            )
        }
        blocks.append(FreeBusyRailBlock(
            title: event.title,
            subtitle: "invite",
            start: event.startDate,
            end: candidateEnd,
            style: .candidate
        ))
        if let suggestedSlot {
            blocks.append(FreeBusyRailBlock(
                title: "\(timeLabel(suggestedSlot)) — you're free",
                subtitle: "suggested",
                start: suggestedSlot,
                end: suggestedSlot.addingTimeInterval(candidateDuration),
                style: .suggested
            ))
        }
        return blocks
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 10) {
            Text("Free/busy read from Apple Calendar on this Mac — no Google Calendar account or server needed.")
                .font(.system(size: 12))
                .foregroundStyle(Color.winnowTextTertiary)
            Spacer()
            Button("Open in Calendar", action: openInCalendar)
                .buttonStyle(.plain)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(Color.winnowAccent)
        }
        .padding(.horizontal, WinnowSpacing.sectionHWide)
        .padding(.vertical, 13)
        .background(Color.winnowSurface)
        .overlay(alignment: .top) { Color.black.opacity(0.05).frame(height: 1) }
    }

    // MARK: - Actions

    private func respond(_ response: RSVPResponse) {
        settings.setRSVP(threadID: thread.id, response: response.rawValue)
        let body: String
        switch response {
        case .yes:   body = "Yes, I'll be there."
        case .maybe: body = "I might be able to make it — I'll confirm closer to the time."
        case .no:    body = "I can't make it, sorry."
        }
        Task { await appState.sendReply(threadID: thread.id, body: body) }
    }

    private func propose(_ time: Date) {
        settings.setRSVP(threadID: thread.id, response: RSVPResponse.maybe.rawValue)
        let body = "Could we move this to \(timeLabel(time))? That works better on my end."
        Task { await appState.sendReply(threadID: thread.id, body: body) }
    }

    private func openInCalendar() {
        let seconds = event.startDate.timeIntervalSinceReferenceDate
        guard let url = URL(string: "calshow:\(Int(seconds))") else { return }
        NSWorkspace.shared.open(url)
    }

    private func loadCalendarData() async {
        let calIDs = settings.calendarCalendarsSeeded ? settings.calendarSelectedIDs : nil
        let dayStart = Calendar.current.startOfDay(for: event.startDate)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? event.startDate.addingTimeInterval(86400)

        railBlocks = await CalendarService.shared.busyBlocks(from: dayStart, to: dayEnd, calendarIDs: calIDs)
        conflicts = await CalendarService.shared.conflicts(withStart: event.startDate, end: candidateEnd, calendarIDs: calIDs)

        guard !conflicts.isEmpty else { return }
        let durationMinutes = max(Int(candidateDuration / 60), 15)
        let slots = await CalendarService.shared.findOpenSlots(
            durationMinutes: durationMinutes,
            within: dayStart...dayEnd,
            workingHours: settings.workingHours,
            calendarIDs: calIDs,
            limit: 5
        )
        suggestedSlot = slots.first { slot in
            let slotEnd = slot.addingTimeInterval(TimeInterval(durationMinutes * 60))
            return !(slot < candidateEnd && slotEnd > event.startDate)
        }
    }

    private func timeLabel(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private var dateRangeLabel: String {
        let dayFmt = event.startDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        guard let end = event.endDate else { return "\(dayFmt) · \(timeLabel(event.startDate))" }
        return "\(dayFmt) · \(timeLabel(event.startDate)) – \(timeLabel(end))"
    }
}
