import SwiftUI
import AppKit
import WinnowCore
import WinnowUI

struct TodayView: View {
    @Environment(AppState.self) private var appState

    private var hour: Int { Calendar.current.component(.hour, from: Date()) }

    private var greeting: String {
        let name = appState.accounts.first?.displayName?
            .components(separatedBy: " ").first ?? "there"
        switch hour {
        case 0..<12:  return "Good morning, \(name)"
        case 12..<18: return "Good afternoon, \(name)"
        default:       return "Good evening, \(name)"
        }
    }

    private var dateString: String {
        Date().formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private var needsReplyThreads: [MailThread] { appState.threads.filter { $0.needsReply } }
    private var packageThreads: [MailThread] {
        appState.threads.filter { t in t.intelligenceResults.contains { if case .packageTracking = $0 { return true }; return false } }
    }
    private var flightThreads: [MailThread] {
        appState.threads.filter { t in t.intelligenceResults.contains { if case .flightInfo = $0 { return true }; return false } }
    }
    private var billThreads: [MailThread] {
        appState.threads.filter { t in t.intelligenceResults.contains { if case .bill = $0 { return true }; return false } }
    }
    private var recentThreads: [MailThread] { Array(appState.threads.prefix(7)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // ── Greeting header ─────────────────────────────────────────
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greeting)
                            .font(WinnowTypography.display)
                            .foregroundStyle(Color.winnowText)
                            .tracking(-0.6)

                        Text(dateString)
                            .font(WinnowTypography.body)
                            .foregroundStyle(Color.winnowTextTertiary)
                    }

                    Spacer()

                    Button {
                        appState.selectedNavItem = .other
                    } label: {
                        HStack(spacing: 6) {
                            Text("Open inbox")
                                .font(WinnowTypography.label)
                            KeycapView("⌘1")
                        }
                        .foregroundStyle(Color.winnowTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: WinnowRadius.pill)
                                .strokeBorder(Color.winnowTextTertiary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.horizontal, WinnowSpacing.sectionH)
                .padding(.top, WinnowSpacing.sectionH)
                .padding(.bottom, 14)

                // ── Briefing line ────────────────────────────────────────────
                HStack(spacing: 6) {
                    AssistDiamond(size: .small)
                    Text(briefing)
                        .font(WinnowTypography.body)
                        .foregroundStyle(Color.winnowTextSecondary)
                }
                .padding(.horizontal, WinnowSpacing.sectionH)
                .padding(.bottom, 28)

                // ── Needs a reply ────────────────────────────────────────────
                if !needsReplyThreads.isEmpty {
                    todaySection(title: "Needs a reply", badge: needsReplyThreads.count, subtitle: "they're waiting on you") {
                        ForEach(needsReplyThreads) { thread in
                            NeedsReplyCard(thread: thread)
                                .onTapGesture {
                                    appState.selectedNavItem = .important
                                    appState.selectThread(thread.id)
                                }
                        }
                    }
                    .padding(.bottom, 24)
                }

                // ── Secondary grid (trips / bills) ───────────────────────────
                if !flightThreads.isEmpty || !packageThreads.isEmpty || !billThreads.isEmpty {
                    HStack(alignment: .top, spacing: 12) {
                        if !billThreads.isEmpty {
                            GridCard(title: "Due soon") {
                                ForEach(billThreads) { thread in BillCard(thread: thread) }
                            }
                        }
                        if !flightThreads.isEmpty || !packageThreads.isEmpty {
                            GridCard(title: "Trips & deliveries") {
                                ForEach(flightThreads) { t in FlightCard(thread: t) }
                                ForEach(packageThreads) { t in PackageCard(thread: t) }
                            }
                        }
                    }
                    .padding(.horizontal, WinnowSpacing.sectionH)
                    .padding(.bottom, 24)
                }

                // ── Recent inbox ─────────────────────────────────────────────
                if !recentThreads.isEmpty {
                    todaySection(title: "Recent inbox", badge: appState.threads.count, subtitle: nil) {
                        VStack(spacing: 0) {
                            ForEach(Array(recentThreads.enumerated()), id: \.element.id) { idx, thread in
                                InboxRow(thread: thread)
                                    .onTapGesture {
                                        appState.selectedNavItem = .other
                                        appState.selectThread(thread.id)
                                    }
                                if idx < recentThreads.count - 1 {
                                    Divider()
                                        .padding(.leading, WinnowSpacing.rowH)
                                        .opacity(0.5)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: WinnowRadius.card)
                                .fill(Color.winnowSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: WinnowRadius.card)
                                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.bottom, 24)
                } else if appState.isLoading {
                    HStack(spacing: 8) {
                        ProgressView().scaleEffect(0.7)
                        Text("Syncing inbox…")
                            .font(WinnowTypography.body)
                            .foregroundStyle(Color.winnowTextTertiary)
                    }
                    .padding(.horizontal, WinnowSpacing.sectionH)
                } else if let error = appState.syncError {
                    Text(error)
                        .font(WinnowTypography.body)
                        .foregroundStyle(Color.winnowAlert)
                        .padding(.horizontal, WinnowSpacing.sectionH)
                }
            }
        }
        .background(Color.winnowSurface)
    }

    // MARK: - Briefing

    private var briefing: String {
        var parts: [String] = []
        if !needsReplyThreads.isEmpty {
            parts.append("\(needsReplyThreads.count) \(needsReplyThreads.count == 1 ? "thread needs" : "threads need") a reply")
        }
        if !packageThreads.isEmpty {
            parts.append("\(packageThreads.count) \(packageThreads.count == 1 ? "package" : "packages") on the way")
        }
        if !billThreads.isEmpty {
            parts.append("\(billThreads.count) renewal\(billThreads.count == 1 ? "" : "s") due soon")
        }
        if parts.isEmpty {
            if appState.isLoading { return "Syncing your inbox…" }
            let unread = appState.threads.filter { !$0.isRead }.count
            if unread > 0 { return "\(unread) unread in inbox." }
            return appState.threads.isEmpty ? "You're all caught up." : "\(appState.threads.count) threads in inbox."
        }
        return parts.joined(separator: " · ") + "."
    }

    // MARK: - Section wrapper

    @ViewBuilder
    private func todaySection<Content: View>(
        title: String,
        badge: Int,
        subtitle: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title.uppercased())
                    .winnowSectionHeader()
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.winnowAccent)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.winnowAccentTint)
                        .cornerRadius(4)
                }
                Spacer()
                if let sub = subtitle {
                    Text(sub)
                        .font(WinnowTypography.meta)
                        .foregroundStyle(Color.winnowTextTertiary)
                }
            }
            content()
        }
        .padding(.horizontal, WinnowSpacing.sectionH)
    }
}

// MARK: - Inbox row

private struct InboxRow: View {
    let thread: MailThread

    var body: some View {
        HStack(spacing: 12) {
            // Unread indicator
            Circle()
                .fill(thread.isRead ? Color.clear : Color.winnowAccent)
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(thread.messages.last?.from.displayName ?? thread.messages.last?.from.email ?? "")
                        .font(WinnowTypography.senderName)
                        .foregroundStyle(Color.winnowText)
                        .lineLimit(1)
                    Spacer()
                    Text(thread.lastMessageDate, style: .time)
                        .font(WinnowTypography.meta)
                        .foregroundStyle(Color.winnowTextTertiary)
                }
                Text(thread.subject)
                    .font(WinnowTypography.messageSubject)
                    .foregroundStyle(!thread.isRead ? Color.winnowText : Color.winnowTextSecondary)
                    .lineLimit(1)
                Text(thread.snippet)
                    .font(WinnowTypography.messagePreview)
                    .foregroundStyle(Color.winnowTextTertiary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, WinnowSpacing.rowH)
        .padding(.vertical, WinnowSpacing.rowV)
        .contentShape(Rectangle())
        .onHover { inside in
            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}

// MARK: - Grid card wrapper

private struct GridCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .winnowSectionHeader()
            content
        }
        .padding(WinnowSpacing.cardH)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: WinnowRadius.card)
                .fill(Color.winnowSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: WinnowRadius.card)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - Needs reply card

private struct NeedsReplyCard: View {
    let thread: MailThread

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.winnowAccentTint)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String((thread.messages.last?.from.displayName ?? "?").prefix(2)).uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.winnowAccent)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(thread.messages.last?.from.displayName ?? "")
                    .font(WinnowTypography.senderName)
                    .foregroundStyle(Color.winnowText)
                Text(thread.subject)
                    .font(WinnowTypography.messageSubject)
                    .foregroundStyle(Color.winnowTextSecondary)
                    .lineLimit(1)
                Text(thread.snippet)
                    .font(WinnowTypography.body)
                    .foregroundStyle(Color.winnowTextTertiary)
                    .lineLimit(1)
            }

            Spacer()

            if thread.hasDraftReady {
                HStack(spacing: 4) {
                    AssistDiamond(size: .small)
                    Text("Draft ready")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.winnowAccent)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.winnowAccentTint)
                .cornerRadius(WinnowRadius.pill)
            }

            Button("Reply") {}
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(WinnowSpacing.cardH)
        .background(
            RoundedRectangle(cornerRadius: WinnowRadius.card)
                .fill(Color.winnowSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: WinnowRadius.card)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - Flight card

private struct FlightCard: View {
    let thread: MailThread

    private var flight: IntelligenceResult.FlightInfo? {
        for r in thread.intelligenceResults { if case .flightInfo(let f) = r { return f } }
        return nil
    }

    var body: some View {
        if let f = flight {
            HStack(spacing: 10) {
                Image(systemName: "airplane")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.winnowAccent)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(f.from) → \(f.to)")
                        .font(WinnowTypography.label)
                        .foregroundStyle(Color.winnowText)
                    Text("\(f.flightNumber) · \(f.departureDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(WinnowTypography.meta)
                        .foregroundStyle(Color.winnowTextTertiary)
                }
            }
        }
    }
}

// MARK: - Package card

private struct PackageCard: View {
    let thread: MailThread

    private var pkg: IntelligenceResult.PackageInfo? {
        for r in thread.intelligenceResults { if case .packageTracking(let p) = r { return p } }
        return nil
    }

    var body: some View {
        if let p = pkg {
            HStack(spacing: 10) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.winnowSuccess)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(thread.subject)
                        .font(WinnowTypography.label)
                        .foregroundStyle(Color.winnowText)
                        .lineLimit(1)
                    Text("\(p.carrier) · \(p.status.label)")
                        .font(WinnowTypography.meta)
                        .foregroundStyle(Color.winnowTextTertiary)
                }
            }
        }
    }
}

// MARK: - Bill card

private struct BillCard: View {
    let thread: MailThread

    private var bill: IntelligenceResult.BillInfo? {
        for r in thread.intelligenceResults { if case .bill(let b) = r { return b } }
        return nil
    }

    var body: some View {
        if let b = bill {
            HStack(spacing: 10) {
                Image(systemName: "repeat")
                    .font(.system(size: 13))
                    .foregroundStyle(b.hasPriceChange ? Color.winnowCaution : Color.winnowTextTertiary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(b.merchant)
                        .font(WinnowTypography.label)
                        .foregroundStyle(Color.winnowText)
                    Text("\(b.currency == "GBP" ? "£" : "$")\(String(format: "%.2f", b.amount))")
                        .font(WinnowTypography.meta)
                        .foregroundStyle(b.hasPriceChange ? Color.winnowCaution : Color.winnowTextTertiary)
                }
                Spacer()
                if let due = b.dueDate {
                    Text("in \(Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0)d")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.winnowCaution)
                }
            }
        }
    }
}
