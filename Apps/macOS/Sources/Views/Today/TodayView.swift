import SwiftUI
import AppKit
import WinnowCore
import WinnowUI

struct TodayView: View {
    @Environment(AppState.self) private var appState

    // MARK: - Derived data

    private var hour: Int { Calendar.current.component(.hour, from: Date()) }

    private var greeting: String {
        let first = appState.accounts.first?.displayName?
            .components(separatedBy: " ").first ?? "there"
        switch hour {
        case 0..<12:  return "Good morning, \(first)"
        case 12..<18: return "Good afternoon, \(first)"
        default:       return "Good evening, \(first)"
        }
    }

    private var dateString: String {
        let f = Date.FormatStyle().weekday(.wide).month(.wide).day()
        return Date().formatted(f)
    }

    private var needsReplyThreads: [MailThread] {
        // Use flagged/important threads as proxy until sent-folder analysis lands
        let nr = appState.threads.filter { $0.needsReply }
        if !nr.isEmpty { return Array(nr.prefix(5)) }
        return Array(appState.threads.filter { $0.labels.contains("IMPORTANT") }.prefix(3))
    }

    private var billThreads: [MailThread] {
        appState.threads.filter { t in
            t.intelligenceResults.contains { if case .bill = $0 { return true }; return false }
        }
    }

    private var packageThreads: [MailThread] {
        appState.threads.filter { t in
            t.intelligenceResults.contains { if case .packageTracking = $0 { return true }; return false }
        }
    }

    private var flightThreads: [MailThread] {
        appState.threads.filter { t in
            t.intelligenceResults.contains { if case .flightInfo = $0 { return true }; return false }
        }
    }

    // Deduplicate packages by tracking number — keep the most recent per track ID.
    private var dedupedPackageThreads: [MailThread] {
        var seen: [String: MailThread] = [:]
        var noTrack: [MailThread] = []
        for thread in packageThreads {
            guard let p = thread.intelligenceResults.compactMap({ r -> IntelligenceResult.PackageInfo? in
                if case .packageTracking(let pkg) = r { return pkg }; return nil
            }).first else { continue }
            if p.trackingNumber.isEmpty {
                noTrack.append(thread)
            } else {
                let key = p.trackingNumber
                if let existing = seen[key] {
                    if thread.lastMessageDate > existing.lastMessageDate { seen[key] = thread }
                } else {
                    seen[key] = thread
                }
            }
        }
        return Array(seen.values).sorted { $0.lastMessageDate > $1.lastMessageDate } + noTrack
    }

    private var totalBillAmount: Double {
        billThreads.compactMap { t in
            for r in t.intelligenceResults { if case .bill(let b) = r { return b.amount } }
            return nil
        }.reduce(0, +)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                greetingHeader
                briefingRow
                needsReplySection
                secondaryGrid
                agentStrip
            }
            .padding(.horizontal, 34)
            .padding(.top, 28)
            .padding(.bottom, 30)
        }
        .background(Color.winnowSurface)
    }

    // MARK: - Greeting header

    private var greetingHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 5) {
                Text(greeting)
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(Color(hex: "161618"))
                    .tracking(-0.5)

                Text(dateString)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.winnowTextTertiary)
            }

            Spacer()

            OpenInboxPill { appState.selectedNavItem = .other }
        }
    }

    // MARK: - Briefing row

    private var briefingRow: some View {
        HStack(alignment: .top, spacing: 9) {
            AssistDiamond(size: .small)
                .padding(.top, 3)

            buildBriefingText()
                .font(.system(size: 14))
                .lineSpacing(4)
                .foregroundStyle(Color.winnowTextSecondary)
        }
        .padding(.top, 16)
        .padding(.bottom, 22)
    }

    private func buildBriefingText() -> Text {
        let unread = appState.threads.filter { !$0.isRead }.count
        let bills  = billThreads.count
        let trips  = flightThreads.count + dedupedPackageThreads.count
        let replies = needsReplyThreads.count

        if appState.isLoading && appState.threads.isEmpty {
            return Text("Syncing your inbox…")
        }
        if appState.threads.isEmpty {
            return Text("You're all caught up.")
        }

        var parts: [Text] = []

        if replies > 0 {
            parts.append(
                Text("\(replies) email\(replies == 1 ? "" : "s")").bold().foregroundStyle(Color.winnowText) +
                Text(" need\(replies == 1 ? "s" : "") a reply")
            )
        }
        if trips > 0 {
            parts.append(
                Text("\(trips) \(trips == 1 ? "shipment" : "shipments or flights")").bold().foregroundStyle(Color.winnowText) +
                Text(" to track")
            )
        }
        if bills > 0 {
            parts.append(
                Text("\(bills == 1 ? "1 bill" : "\(bills) bills")").bold().foregroundStyle(Color.winnowText) +
                Text(bills == 1 ? " is due soon" : " are due soon")
            )
        }

        if parts.isEmpty {
            return Text("\(unread) unread").bold().foregroundStyle(Color.winnowText) + Text(" in inbox.")
        }

        var combined = parts[0]
        for (i, part) in parts.dropFirst().enumerated() {
            combined = combined + Text(i == parts.count - 2 ? ", and " : ", ") + part
        }
        return combined + Text(".")
    }

    // MARK: - Needs a reply (hero card)

    @ViewBuilder
    private var needsReplySection: some View {
        if !needsReplyThreads.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                // Card header
                HStack(spacing: 8) {
                    Text("Needs a reply")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.winnowText)

                    Text("\(needsReplyThreads.count)")
                        .font(.system(size: 11, weight: .semibold).monospaced())
                        .foregroundStyle(Color.winnowAccent)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 1)
                        .background(Color.winnowAccentTint)
                        .clipShape(RoundedRectangle(cornerRadius: 5))

                    Spacer()

                    Text("they're waiting on you")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: "B2B2B8"))
                }
                .padding(.horizontal, 19)
                .padding(.top, 16)
                .padding(.bottom, 6)

                // Rows with internal dividers
                ForEach(Array(needsReplyThreads.enumerated()), id: \.element.id) { _, thread in
                    Divider().opacity(0.5)
                    NeedsReplyRow(thread: thread) {
                        appState.selectedNavItem = .other
                        appState.selectThread(thread.id)
                    }
                }

                Spacer().frame(height: 8)
            }
            .background(Color.winnowSurface)
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
            )
            .padding(.bottom, 16)
        }
    }

    // MARK: - Secondary 3-column grid

    private var secondaryGrid: some View {
        HStack(alignment: .top, spacing: 16) {
            FollowingUpCard()
            DueSoonCard(threads: billThreads, total: totalBillAmount)
            TripsCard(flightThreads: flightThreads, packageThreads: dedupedPackageThreads)
        }
        .padding(.bottom, 16)
    }

    // MARK: - Agent strip

    @ViewBuilder
    private var agentStrip: some View {
        if let date = appState.lastSyncDate {
            let ago = Int(Date().timeIntervalSince(date) / 60)
            HStack(spacing: 11) {
                AssistDiamond(size: .small)
                    .frame(width: 8, height: 8)

                Group {
                    Text("Winnow synced ").foregroundStyle(Color.winnowTextSecondary) +
                    Text("just now").bold().foregroundStyle(Color.winnowText)
                    + Text(ago == 0 ? "" : " \(ago)m ago")
                        .foregroundStyle(Color.winnowTextSecondary)
                }
                .font(.system(size: 13))
                .lineSpacing(4)

                Spacer()

                AgentRefreshButton { Task { await appState.syncInbox() } }
            }
            .padding(.horizontal, 17)
            .padding(.vertical, 13)
            .background(Color(hex: "F7F9FC"))
            .clipShape(RoundedRectangle(cornerRadius: 11))
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .strokeBorder(Color.winnowAccent.opacity(0.10), lineWidth: 1)
            )
        }
    }
}

// MARK: - Needs Reply Row

private struct NeedsReplyRow: View {
    let thread: MailThread
    let onTap: () -> Void
    @State private var isHovered = false

    private var sender: String {
        thread.messages.last?.from.displayName ?? thread.messages.last?.from.email ?? "Unknown"
    }

    private var initials: String {
        let words = sender.components(separatedBy: " ")
        let first = String(words.first?.prefix(1) ?? "?").uppercased()
        let last  = String(words.dropFirst().first?.prefix(1) ?? "").uppercased()
        return first + last
    }

    private var waitingLabel: String {
        let age = Date().timeIntervalSince(thread.lastMessageDate)
        if age < 3600     { return "waiting \(max(1, Int(age / 60)))m" }
        if age < 86400    { return "waiting \(Int(age / 3600))h" }
        return "waiting \(Int(age / 86400))d"
    }

    private var avatarColors: (bg: Color, fg: Color) {
        let palette: [(String, String)] = [
            ("fbe7ea","c0566c"), ("e8eafb","5a5fc0"), ("e4f0e8","4f9168"),
            ("f3ece0","a07d3a"), ("dbe6f8","2f6bdb"), ("eef0f4","6a7184"),
        ]
        let idx = abs(sender.hashValue) % palette.count
        return (Color(hex: palette[idx].0), Color(hex: palette[idx].1))
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Avatar
            let colors = avatarColors
            Circle()
                .fill(colors.bg)
                .frame(width: 34, height: 34)
                .overlay(
                    Text(initials)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(colors.fg)
                )

            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 9) {
                    Text(sender)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.winnowText)
                        .lineLimit(1)

                    Text(waitingLabel)
                        .font(.system(size: 11, weight: .medium).monospaced())
                        .foregroundStyle(Color(hex: "B2B2B8"))
                }

                Text(thread.subject)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "3A3A40"))
                    .lineLimit(1)

                Text(thread.snippet)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.winnowTextTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // Draft ready badge (when applicable)
            if thread.hasDraftReady {
                HStack(spacing: 5) {
                    AssistDiamond(size: .small)
                    Text("Draft ready")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.winnowAccent)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.winnowAccentTint)
                .clipShape(Capsule())
            }

            // Reply button
            Button("Reply") { onTap() }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.winnowAccent)
                .padding(.horizontal, 13)
                .padding(.vertical, 5)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.winnowAccent.opacity(0.28), lineWidth: 1)
                )
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 19)
        .padding(.vertical, 14)
        .background(isHovered ? Color.winnowHover : .clear)
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .onHover { isHovered = $0 }
    }
}

// MARK: - Following Up Card

private struct FollowingUpCard: View {
    var body: some View {
        TodayCard {
            todayCardHeader(title: "Following up")
            // Placeholder until sent-folder analysis is implemented
            VStack(alignment: .leading, spacing: 0) {
                Divider().opacity(0.4).padding(.top, 6)
                emptyRow("No sent threads awaiting reply")
            }
            Spacer().frame(height: 8)
        }
    }

    private func emptyRow(_ msg: String) -> some View {
        Text(msg)
            .font(.system(size: 12))
            .foregroundStyle(Color.winnowTextTertiary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Due Soon Card

private struct DueSoonCard: View {
    let threads: [MailThread]
    let total: Double

    var body: some View {
        TodayCard {
            // Header with diamond + total
            HStack(spacing: 8) {
                AssistDiamond(size: .small)
                Text("DUE SOON")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.05 * 11)
                    .foregroundStyle(Color(hex: "9AA6BB"))
                Spacer()
                if total > 0 {
                    Text("≈\(currencyString(total))")
                        .font(.system(size: 11, weight: .semibold).monospaced())
                        .foregroundStyle(Color(hex: "34343A"))
                }
            }
            .padding(.horizontal, 17)
            .padding(.top, 14)
            .padding(.bottom, 4)

            if threads.isEmpty {
                Divider().opacity(0.4).padding(.top, 6)
                Text("No bills due soon")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.winnowTextTertiary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(Array(threads.prefix(4).enumerated()), id: \.element.id) { i, thread in
                    if i == 0 { Divider().opacity(0.4).padding(.top, 6) } else { Divider().opacity(0.4) }
                    BillDueSoonRow(thread: thread)
                }
            }
            Spacer().frame(height: 8)
        }
    }

    private func currencyString(_ amount: Double) -> String {
        let formatted = String(format: "%.0f", amount)
        return "$\(formatted)"
    }
}

private struct BillDueSoonRow: View {
    let thread: MailThread
    @Environment(AppState.self) private var appState
    @State private var isHovered = false

    private var bill: IntelligenceResult.BillInfo? {
        for r in thread.intelligenceResults { if case .bill(let b) = r { return b } }
        return nil
    }

    var body: some View {
        if let b = bill {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(b.merchant)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Color.winnowText)
                        .lineLimit(1)
                    if let due = b.dueDate {
                        Text(due.formatted(.dateTime.month().day()))
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "A2A2A8"))
                    } else {
                        Text(thread.lastMessageDate.formatted(.dateTime.month().day()))
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "A2A2A8"))
                    }
                }
                Spacer()
                Text(amountString(b))
                    .font(.system(size: 12.5, weight: .semibold).monospaced())
                    .foregroundStyle(Color(hex: "34343A"))
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(isHovered ? Color.winnowHover : .clear)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
            .contentShape(Rectangle())
            .onTapGesture {
                appState.selectedNavItem = .other
                appState.selectThread(thread.id)
            }
            .onHover { isHovered = $0 }
        }
    }

    private func amountString(_ b: IntelligenceResult.BillInfo) -> String {
        let symbol: String
        switch b.currency {
        case "GBP": symbol = "£"
        case "EUR": symbol = "€"
        case "AUD": symbol = "A$"
        default:    symbol = "$"
        }
        return "\(symbol)\(b.amount == b.amount.rounded() ? String(format: "%.0f", b.amount) : String(format: "%.2f", b.amount))"
    }
}

// MARK: - Trips & Deliveries Card

private struct TripsCard: View {
    let flightThreads: [MailThread]
    let packageThreads: [MailThread]

    private var cardTitle: String {
        switch (flightThreads.isEmpty, packageThreads.isEmpty) {
        case (false, false): return "Trips & deliveries"
        case (false, true):  return "Trips"
        case (true, false):  return "Deliveries"
        default:             return "Trips & deliveries"
        }
    }

    var body: some View {
        TodayCard {
            todayCardHeader(title: cardTitle)

            let allThreads = flightThreads + packageThreads
            if allThreads.isEmpty {
                Divider().opacity(0.4).padding(.top, 6)
                Text("No upcoming trips or deliveries")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.winnowTextTertiary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(Array(allThreads.prefix(4).enumerated()), id: \.element.id) { i, thread in
                    if i == 0 { Divider().opacity(0.4).padding(.top, 6) } else { Divider().opacity(0.4) }
                    TripRow(thread: thread)
                }
            }
            Spacer().frame(height: 8)
        }
    }
}

private struct TripRow: View {
    let thread: MailThread
    @Environment(AppState.self) private var appState
    @State private var isHovered = false

    private var flight: IntelligenceResult.FlightInfo? {
        for r in thread.intelligenceResults { if case .flightInfo(let f) = r { return f } }
        return nil
    }
    private var pkg: IntelligenceResult.PackageInfo? {
        for r in thread.intelligenceResults { if case .packageTracking(let p) = r { return p } }
        return nil
    }

    var body: some View {
        HStack(alignment: .center, spacing: 11) {
            iconBox

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Color.winnowText)
                    .lineLimit(1)
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.winnowTextTertiary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isHovered ? Color.winnowHover : .clear)
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .contentShape(Rectangle())
        .onTapGesture {
            appState.selectedNavItem = flight != nil ? .flights : .deliveries
            appState.selectThread(thread.id)
        }
        .onHover { isHovered = $0 }
    }

    private var title: String {
        if let f = flight { return "\(f.from) → \(f.to)" }
        if let p = pkg    { return p.status.label }
        return thread.subject
    }

    private var detail: String {
        if let f = flight {
            return "\(f.flightNumber) · \(f.departureDate.formatted(.dateTime.month(.abbreviated).day()))"
        }
        if let p = pkg {
            // Use sender name when carrier is the generic fallback
            let carrier = p.carrier == "Courier"
                ? (thread.messages.first?.from.displayName ?? "Courier")
                : p.carrier
            if p.trackingNumber.isEmpty { return carrier }
            return "\(carrier) · \(p.trackingNumber.prefix(12))"
        }
        return thread.snippet
    }

    private var iconBox: some View {
        Group {
            if flight != nil {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "F1EDDC"))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "airplane")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "A07D1A"))
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "DBE6F8"))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.winnowAccent)
                    )
            }
        }
        .frame(width: 30, height: 30)
    }
}

// MARK: - Shared card chrome

private struct TodayCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.winnowSurface)
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
        )
    }
}

// MARK: - Open inbox pill

private struct OpenInboxPill: View {
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text("Open inbox")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.winnowTextTertiary)
                Text("⌘1")
                    .font(.system(size: 11, weight: .semibold).monospaced())
                    .foregroundStyle(Color(hex: "B2B2B8"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(isHovered ? Color.winnowHover : .clear)
                    .animation(.easeInOut(duration: 0.12), value: isHovered)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .strokeBorder(Color.black.opacity(isHovered ? 0.14 : 0.10), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Agent strip refresh button

private struct AgentRefreshButton: View {
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text("Refresh")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(Color.winnowAccent)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovered ? Color.winnowAccentTint : .clear)
                        .animation(.easeInOut(duration: 0.12), value: isHovered)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

private func todayCardHeader(title: String, badge: Int? = nil) -> some View {
    HStack(spacing: 8) {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(Color(hex: "9AA6BB"))
        if let b = badge, b > 0 {
            Text("\(b)")
                .font(.system(size: 11, weight: .semibold).monospaced())
                .foregroundStyle(Color.winnowAccent)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(Color.winnowAccentTint)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        Spacer()
    }
    .padding(.horizontal, 17)
    .padding(.top, 14)
    .padding(.bottom, 4)
}
