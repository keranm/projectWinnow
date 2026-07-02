import Foundation
import WinnowCore

/// Shared "Find a time" helper used by both the reply box and new-message compose window —
/// suggests open slots from EventKit free/busy, formatted for dropping straight into a body.
enum FindATime {
    static func suggestionText(
        calendarIDs: Set<String>?,
        workingHours: WorkingHours,
        durationMinutes: Int = 45
    ) async -> String? {
        let now = Date()
        guard let horizon = Calendar.current.date(byAdding: .day, value: 7, to: now) else { return nil }

        let slots = await CalendarService.shared.findOpenSlots(
            durationMinutes: durationMinutes,
            within: now...horizon,
            workingHours: workingHours,
            calendarIDs: calendarIDs,
            limit: 3
        )
        guard !slots.isEmpty else { return nil }

        let lines = slots.map { slot -> String in
            let label = slot.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
            return "• \(label) (\(durationMinutes) min)"
        }
        return "Here are a few times I'm free:\n" + lines.joined(separator: "\n")
    }
}
