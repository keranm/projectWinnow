import SwiftUI
import WinnowCore
import WinnowUI

struct CalendarPanel: View {
    @Environment(WinnowSettings.self) private var settings
    @State private var accessState: CalendarService.AccessState = .notDetermined
    @State private var calendars: [CalendarInfo] = []
    @State private var isRequesting = false

    var body: some View {
        @Bindable var s = settings

        VStack(alignment: .leading, spacing: 0) {
            Text("Calendar")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(hex: "161618"))
                .tracking(-0.2)

            Text("Winnow reads your schedule from Apple Calendar — which already syncs Google, iCloud & Exchange. One permission, everything local.")
                .font(.system(size: 12.5))
                .foregroundStyle(Color(hex: "8A8A90"))
                .lineSpacing(3)
                .frame(maxWidth: 560, alignment: .leading)
                .padding(.top, 5)

            sourceRow.padding(.top, 18)

            if accessState == .granted {
                SettingsSectionHeader(title: "Show these calendars").padding(.top, 22)
                calendarGrid.padding(.top, 10)
            }

            SettingsSectionHeader(title: "Availability").padding(.top, 22)
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Working hours").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.winnowText)
                        Text("\u{201C}Find a time\u{201D} only suggests inside these").font(.system(size: 11.5)).foregroundStyle(Color(hex: "A2A2A8"))
                    }
                    Spacer()
                    workingHoursPicker
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)

                Divider().opacity(0.4)
                SettingsToggleRow(
                    title: "Show free/busy beside invites",
                    subtitle: "",
                    isOn: $s.calendarShowFreeBusyBesideInvites
                ) { settings.save() }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)

                Divider().opacity(0.4)
                SettingsToggleRow(
                    title: "Flag conflicts on incoming invites",
                    subtitle: "",
                    isOn: $s.calendarFlagConflicts
                ) { settings.save() }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
            }
            .background(Color.winnowSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.black.opacity(0.07), lineWidth: 1))
            .padding(.top, 10)

            HStack(alignment: .top, spacing: 8) {
                AssistDiamond(size: .small).padding(.top, 3)
                Text("RSVPs send through the invite's own account. Winnow never asks for a separate Google Calendar permission.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "8A8A90"))
                    .lineSpacing(3)
            }
            .padding(.top, 16)
        }
        .task { await refresh() }
    }

    private var sourceRow: some View {
        HStack(spacing: 13) {
            Text("31")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Color(hex: "E0533D"))
                .clipShape(RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 2) {
                Text("Apple Calendar · EventKit")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Color.winnowText)
                Text(sourceSubtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "8A8A90"))
            }

            Spacer()

            switch accessState {
            case .granted:
                Text("ACTIVE")
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(0.4)
                    .foregroundStyle(Color.winnowSuccess)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "E8F4EE"))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            case .notDetermined:
                Button(isRequesting ? "Requesting…" : "Connect") { Task { await requestAccess() } }
                    .buttonStyle(WinnowPrimaryButton())
                    .disabled(isRequesting)
            case .denied:
                Text("DENIED — enable in System Settings")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Color.winnowAlert)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: "F7F9FC"))
        .clipShape(RoundedRectangle(cornerRadius: 11))
        .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(Color.winnowAccent.opacity(0.14), lineWidth: 1))
    }

    private var sourceSubtitle: String {
        switch accessState {
        case .granted: "Connected · free/busy + invites read on this Mac"
        case .notDetermined: "Not connected — grant access to see free/busy and conflicts"
        case .denied: "Access denied — Winnow can't read your calendar"
        }
    }

    private var calendarGrid: some View {
        @Bindable var s = settings
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible())], spacing: 9) {
            ForEach(calendars) { cal in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: cal.colorHex))
                        .frame(width: 13, height: 13)
                    Text(cal.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.winnowText)
                        .lineLimit(1)
                    Spacer()
                    let isOn = s.calendarSelectedIDs.contains(cal.id)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isOn ? Color.winnowAccent : Color.clear)
                        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(isOn ? .clear : Color(hex: "C2C2C8"), lineWidth: 1.5))
                        .frame(width: 18, height: 18)
                        .overlay {
                            if isOn {
                                Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isOn { s.calendarSelectedIDs.remove(cal.id) } else { s.calendarSelectedIDs.insert(cal.id) }
                            settings.save()
                        }
                }
            }
        }
    }

    private var workingHoursPicker: some View {
        @Bindable var s = settings
        return HStack(spacing: 6) {
            Picker("", selection: $s.calendarWorkingHoursStart) {
                ForEach(0..<24) { h in Text(hourLabel(h)).tag(h) }
            }
            .labelsHidden()
            .frame(width: 74)
            .onChange(of: s.calendarWorkingHoursStart) { settings.save() }

            Text("–").foregroundStyle(Color.winnowTextTertiary)

            Picker("", selection: $s.calendarWorkingHoursEnd) {
                ForEach(0..<24) { h in Text(hourLabel(h)).tag(h) }
            }
            .labelsHidden()
            .frame(width: 74)
            .onChange(of: s.calendarWorkingHoursEnd) { settings.save() }
        }
        .font(.system(size: 12.5, weight: .medium).monospaced())
    }

    private func hourLabel(_ hour: Int) -> String {
        let period = hour < 12 ? "am" : "pm"
        let h12 = hour % 12 == 0 ? 12 : hour % 12
        return "\(h12)\(period)"
    }

    private func refresh() async {
        accessState = CalendarService.shared.authorizationState
        if accessState == .granted {
            calendars = await CalendarService.shared.availableCalendars()
            settings.seedCalendarsIfNeeded(calendars)
        }
    }

    private func requestAccess() async {
        isRequesting = true
        let granted = await CalendarService.shared.requestAccess()
        accessState = granted ? .granted : .denied
        if granted {
            calendars = await CalendarService.shared.availableCalendars()
            settings.seedCalendarsIfNeeded(calendars)
        }
        isRequesting = false
    }
}
