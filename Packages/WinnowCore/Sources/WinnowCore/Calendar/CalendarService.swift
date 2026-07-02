import EventKit
import Foundation

/// Wraps EventKit for free/busy reads and conflict detection — per ADR 003, this is the
/// only calendar integration Winnow has. No Google Calendar API scope is requested; EventKit
/// already aggregates Google/iCloud/Exchange calendars the user has configured on-device.
public actor CalendarService {
    public static let shared = CalendarService()
    private let store = EKEventStore()
    private init() {}

    public enum AccessState: Sendable {
        case notDetermined, granted, denied
    }

    public nonisolated var authorizationState: AccessState {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .authorized: return .granted
        case .notDetermined: return .notDetermined
        default: return .denied
        }
    }

    @discardableResult
    public func requestAccess() async -> Bool {
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    public func availableCalendars() -> [CalendarInfo] {
        store.calendars(for: .event).map {
            CalendarInfo(id: $0.calendarIdentifier, title: $0.title, colorHex: Self.hexString(from: $0.cgColor))
        }
    }

    public func busyBlocks(from start: Date, to end: Date, calendarIDs: Set<String>? = nil) -> [BusyBlock] {
        let calendars = calendars(for: calendarIDs)
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        return store.events(matching: predicate).map {
            BusyBlock(title: $0.title ?? "Busy", start: $0.startDate, end: $0.endDate)
        }
    }

    public func conflicts(withStart start: Date, end: Date, calendarIDs: Set<String>? = nil) -> [BusyBlock] {
        busyBlocks(from: start, to: end, calendarIDs: calendarIDs).filter { $0.start < end && $0.end > start }
    }

    /// Walks forward from `range.lowerBound` in `stepMinutes` increments, within `workingHours`,
    /// returning the first `limit` slots of `durationMinutes` with no conflicting event.
    public func findOpenSlots(
        durationMinutes: Int,
        within range: ClosedRange<Date>,
        workingHours: WorkingHours = .default,
        calendarIDs: Set<String>? = nil,
        stepMinutes: Int = 30,
        limit: Int = 3
    ) -> [Date] {
        let calendar = Calendar.current
        let busy = busyBlocks(from: range.lowerBound, to: range.upperBound, calendarIDs: calendarIDs)
        let duration = TimeInterval(durationMinutes * 60)

        var slots: [Date] = []
        var cursor = calendar.nextDate(
            after: range.lowerBound.addingTimeInterval(-1),
            matching: DateComponents(minute: 0),
            matchingPolicy: .nextTimePreservingSmallerComponents
        ) ?? range.lowerBound

        while cursor < range.upperBound && slots.count < limit {
            defer { cursor = cursor.addingTimeInterval(TimeInterval(stepMinutes * 60)) }

            let weekday = calendar.component(.weekday, from: cursor)
            guard workingHours.weekdays.contains(weekday) else { continue }

            let hour = calendar.component(.hour, from: cursor)
            guard hour >= workingHours.startHour && hour < workingHours.endHour else { continue }

            guard let dayEnd = calendar.date(bySettingHour: workingHours.endHour, minute: 0, second: 0, of: cursor)
            else { continue }
            let slotEnd = cursor.addingTimeInterval(duration)
            guard slotEnd <= dayEnd else { continue }

            let hasConflict = busy.contains { $0.start < slotEnd && $0.end > cursor }
            if !hasConflict {
                slots.append(cursor)
            }
        }

        return slots
    }

    // MARK: - Private

    private func calendars(for ids: Set<String>?) -> [EKCalendar]? {
        guard let ids else { return nil }
        return store.calendars(for: .event).filter { ids.contains($0.calendarIdentifier) }
    }

    private static func hexString(from color: CGColor?) -> String {
        guard let components = color?.components, components.count >= 3 else { return "9AA6BB" }
        let r = Int((components[0] * 255).rounded())
        let g = Int((components[1] * 255).rounded())
        let b = Int((components[2] * 255).rounded())
        return String(format: "%02X%02X%02X", r, g, b)
    }
}

public struct CalendarInfo: Sendable, Identifiable, Hashable {
    public let id: String
    public let title: String
    public let colorHex: String
}

public struct BusyBlock: Sendable {
    public let title: String
    public let start: Date
    public let end: Date
}

public struct WorkingHours: Sendable {
    public let startHour: Int
    public let endHour: Int
    public let weekdays: Set<Int>  // Calendar.component(.weekday) — 1 = Sunday ... 7 = Saturday

    public init(startHour: Int, endHour: Int, weekdays: Set<Int>) {
        self.startHour = startHour
        self.endHour = endHour
        self.weekdays = weekdays
    }

    public static let `default` = WorkingHours(startHour: 9, endHour: 18, weekdays: [2, 3, 4, 5, 6])
}
