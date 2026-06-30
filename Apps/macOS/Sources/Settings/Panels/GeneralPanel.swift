import SwiftUI
import WinnowUI

struct GeneralPanel: View {
    @Environment(WinnowSettings.self) private var settings

    var body: some View {
        @Bindable var s = settings
        VStack(alignment: .leading, spacing: 0) {
            Text("General")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(hex: "161618"))
                .tracking(-0.2)

            SettingsSectionHeader(title: "Appearance").padding(.top, 26)

            VStack(spacing: 0) {
                settingsRow("Thread density") {
                    Picker("", selection: $s.threadDensity) {
                        Text("Comfortable").tag("comfortable")
                        Text("Compact").tag("compact")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    .onChange(of: s.threadDensity) { _, _ in settings.save() }
                }
                Divider().opacity(0.4)
                settingsRow("Dock badge") {
                    WinnowToggle(isOn: $s.showDockBadge) { settings.save() }
                }
            }
            .background(Color.winnowSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.black.opacity(0.07), lineWidth: 1))
            .padding(.top, 11)
        }
    }

    private func settingsRow<T: View>(_ label: String, @ViewBuilder trailing: () -> T) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.winnowText)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}
