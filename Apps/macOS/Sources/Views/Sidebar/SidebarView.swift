import SwiftUI
import WinnowUI
import WinnowCore

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            accountChip

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sectionLabel("Inbox")
                        .padding(.bottom, 4)

                    ForEach(NavItem.primaryItems, id: \.self) { item in
                        SidebarRow(
                            item: item,
                            isSelected: appState.selectedNavItem == item,
                            count: appState.count(for: item)
                        ) { appState.selectedNavItem = item }
                    }

                    HStack(spacing: 5) {
                        AssistDiamond(size: .small)
                        sectionLabel("Pulled from mail")
                    }
                    .padding(.top, 18)
                    .padding(.bottom, 4)

                    ForEach(NavItem.pulledItems, id: \.self) { item in
                        SidebarRow(
                            item: item,
                            isSelected: appState.selectedNavItem == item,
                            count: appState.count(for: item)
                        ) { appState.selectedNavItem = item }
                    }
                }
                .padding(.top, 6)
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
                initialsAvatar(account)

                VStack(alignment: .leading, spacing: 1) {
                    Text(account.displayName ?? account.email)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.winnowText)
                        .lineLimit(1)
                    Text(account.email)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.winnowTextTertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    private func initialsAvatar(_ account: Account) -> some View {
        let palette: [(bg: String, fg: String)] = [
            ("e7ecf6", "2f6bdb"), ("fbe7ea", "c0566c"), ("e4f0e8", "4f9168"),
            ("f3ece0", "a07d3a"), ("e8eafb", "5a5fc0"), ("eef0f4", "6a7184"),
        ]
        let idx = abs(account.email.hashValue) % palette.count
        let pair = palette[idx]
        return Circle()
            .fill(Color(hex: pair.bg))
            .frame(width: 30, height: 30)
            .overlay(
                Text(account.initials)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: pair.fg))
            )
    }

    // MARK: - Section label

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10.5, weight: .semibold))
            .tracking(0.7)
            .foregroundStyle(Color.winnowTextQuaternary)
            .padding(.horizontal, 10)
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
                .font(.system(size: 11))
                .foregroundStyle(appState.syncError == nil ? Color.winnowTextTertiary : Color.winnowAlert)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
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
            HStack {
                Text(item.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.winnowText : Color.winnowTextSecondary)

                Spacer()

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: isSelected ? .semibold : .medium, design: .monospaced))
                        .foregroundStyle(isSelected ? Color.winnowAccent : Color.winnowTextQuaternary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isSelected ? Color.winnowAccentTint : Color.clear)
                    if isSelected {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.winnowAccent)
                            .frame(width: 2)
                            .padding(.vertical, 3)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
        .padding(.vertical, 1)
    }
}
