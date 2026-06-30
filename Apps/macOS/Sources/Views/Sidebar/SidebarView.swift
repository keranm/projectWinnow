import SwiftUI
import WinnowUI
import WinnowCore

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            accountChip

            Divider().opacity(0.5)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Primary nav
                    ForEach(NavItem.primaryItems, id: \.self) { item in
                        SidebarRow(
                            item: item,
                            isSelected: appState.selectedNavItem == item,
                            count: appState.count(for: item)
                        ) {
                            appState.selectedNavItem = item
                        }
                    }

                    // Pulled from mail
                    HStack(spacing: 5) {
                        AssistDiamond(size: .small)
                        Text("Pulled from mail")
                            .winnowSectionHeader()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 22)
                    .padding(.bottom, 6)

                    ForEach(NavItem.pulledItems, id: \.self) { item in
                        SidebarRow(
                            item: item,
                            isSelected: appState.selectedNavItem == item,
                            count: appState.count(for: item)
                        ) {
                            appState.selectedNavItem = item
                        }
                    }
                }
                .padding(.top, 8)
            }

            Spacer(minLength: 0)
            Divider().opacity(0.5)
            syncFooter
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.winnowSidebar)
    }

    // MARK: - Account chip

    private var accountChip: some View {
        HStack(spacing: 10) {
            if let account = appState.accounts.first {
                Circle()
                    .fill(Color(hex: account.color.hex))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(account.initials)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(account.displayName ?? account.email)
                        .font(WinnowTypography.label)
                        .foregroundStyle(Color.winnowText)
                        .lineLimit(1)
                    Text(account.email)
                        .font(WinnowTypography.meta)
                        .foregroundStyle(Color.winnowTextTertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.winnowTextTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Sync footer

    private var syncFooter: some View {
        HStack(spacing: 6) {
            if appState.isLoading {
                ProgressView().scaleEffect(0.5).frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(appState.syncError == nil ? Color.winnowSuccess : Color.winnowAlert)
                    .frame(width: 6, height: 6)
            }
            Text(syncFooterLabel)
                .font(WinnowTypography.meta)
                .foregroundStyle(appState.syncError == nil ? Color.winnowTextTertiary : Color.winnowAlert)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var syncFooterLabel: String {
        if let error = appState.syncError { return error }
        if appState.isLoading { return "Syncing…" }
        guard let date = appState.lastSyncDate else { return "On-device" }
        let mins = Int(Date().timeIntervalSince(date) / 60)
        if mins < 1 { return "On-device · just now" }
        return "On-device · \(mins)m ago"
    }
}

// MARK: - Row

private struct SidebarRow: View {
    let item: NavItem
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Diamond selection indicator — occupies fixed 20pt leading slot
                ZStack {
                    if isSelected {
                        AssistDiamond(size: .small)
                    }
                }
                .frame(width: 20)

                Text(item.title)
                    .font(WinnowTypography.label)
                    .foregroundStyle(isSelected ? Color.winnowText : Color.winnowTextSecondary)

                Spacer()

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(isSelected ? Color.winnowAccent : Color.winnowTextTertiary)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: WinnowRadius.row)
                    .fill(isSelected ? Color.winnowAccentTint : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
        .padding(.vertical, 1)
    }
}
