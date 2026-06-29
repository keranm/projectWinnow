import SwiftUI
import WinnowCore
import WinnowUI

struct TodayView: View {
    @Environment(AppState.self) private var appState

    private var hour: Int { Calendar.current.component(.hour, from: Date()) }
    private var greeting: String {
        let name = appState.accounts.first?.displayName?.components(separatedBy: " ").first ?? "there"
        switch hour {
        case 0..<12:  return "Good morning, \(name)."
        case 12..<18: return "Good afternoon, \(name)."
        default:       return "Good evening, \(name)."
        }
    }

    private var needsReplyThreads: [MailThread] {
        appState.threads.filter { $0.needsReply }
    }

    private var packageThreads: [MailThread] {
        appState.threads.filter { thread in
            thread.intelligenceResults.contains { if case .packageTracking = $0 { return true }; return false }
        }
    }

    private var flightThreads: [MailThread] {
        appState.threads.filter { thread in
            thread.intelligenceResults.contains { if case .flightInfo = $0 { return true }; return false }
        }
    }

    private var billThreads: [MailThread] {
        appState.threads.filter { thread in
            thread.intelligenceResults.contains { if case .bill = $0 { return true }; return false }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Greeting
                VStack(alignment: .leading, spacing: 6) {
                    Text(greeting)
                        .font(WinnowTypography.display)
                        .foregroundStyle(Color.winnowText)
                        .tracking(-0.6)

                    briefingLine
                }
                .padding(.top, 8)

                // Needs a reply
                if !needsReplyThreads.isEmpty {
                    TodaySection(title: "Needs a reply") {
                        ForEach(needsReplyThreads) { thread in
                            NeedsReplyCard(thread: thread)
                                .onTapGesture {
                                    appState.selectedNavItem = .important
                                    appState.selectThread(thread.id)
                                }
                        }
                    }
                }

                // Trips & deliveries
                if !flightThreads.isEmpty || !packageThreads.isEmpty {
                    TodaySection(title: "Trips & deliveries") {
                        ForEach(flightThreads) { thread in
                            FlightCard(thread: thread)
                        }
                        ForEach(packageThreads) { thread in
                            PackageCard(thread: thread)
                        }
                    }
                }

                // Due soon (bills)
                if !billThreads.isEmpty {
                    TodaySection(title: "Due soon") {
                        ForEach(billThreads) { thread in
                            BillCard(thread: thread)
                        }
                    }
                }
            }
            .padding(.horizontal, WinnowSpacing.sectionH)
            .padding(.vertical, WinnowSpacing.sectionH)
        }
        .background(Color.winnowSurface)
    }

    private var briefingLine: some View {
        HStack(spacing: 6) {
            AssistDiamond(size: .small)
            Text(buildBriefing())
                .font(WinnowTypography.body)
                .foregroundStyle(Color.winnowTextSecondary)
        }
    }

    private func buildBriefing() -> String {
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
        if parts.isEmpty { return "You're all caught up." }
        return parts.joined(separator: " · ") + "."
    }
}

// MARK: - Section wrapper

private struct TodaySection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .winnowSectionHeader()
            content
        }
    }
}

// MARK: - Cards

private struct NeedsReplyCard: View {
    let thread: MailThread

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(thread.messages.last?.from.displayName ?? "")
                    .font(WinnowTypography.senderName)
                    .foregroundStyle(Color.winnowText)

                Spacer()

                if thread.hasDraftReady {
                    HStack(spacing: 4) {
                        AssistDiamond(size: .small)
                        Text("Draft ready")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.winnowAccent)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.winnowAccentTint)
                    .cornerRadius(WinnowRadius.pill)
                }
            }

            Text(thread.subject)
                .font(WinnowTypography.label)
                .foregroundStyle(Color.winnowText)

            Text(thread.snippet)
                .font(WinnowTypography.body)
                .foregroundStyle(Color.winnowTextSecondary)
                .lineLimit(2)
        }
        .padding(WinnowSpacing.cardH)
        .background(
            RoundedRectangle(cornerRadius: WinnowRadius.card)
                .fill(Color.winnowSurface)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: WinnowRadius.card)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

private struct FlightCard: View {
    let thread: MailThread

    private var flight: IntelligenceResult.FlightInfo? {
        for result in thread.intelligenceResults {
            if case .flightInfo(let info) = result { return info }
        }
        return nil
    }

    var body: some View {
        if let f = flight {
            HStack(spacing: 14) {
                Image(systemName: "airplane")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.winnowAccent)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(f.from)
                            .font(WinnowTypography.senderName)
                        Text("→")
                            .foregroundStyle(Color.winnowTextTertiary)
                        Text(f.to)
                            .font(WinnowTypography.senderName)
                    }
                    .foregroundStyle(Color.winnowText)

                    Text("\(f.flightNumber) · \(f.departureDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(WinnowTypography.meta)
                        .foregroundStyle(Color.winnowTextTertiary)
                }

                Spacer()
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
}

private struct PackageCard: View {
    let thread: MailThread

    private var pkg: IntelligenceResult.PackageInfo? {
        for result in thread.intelligenceResults {
            if case .packageTracking(let info) = result { return info }
        }
        return nil
    }

    var body: some View {
        if let p = pkg {
            HStack(spacing: 14) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.winnowSuccess)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(thread.subject)
                        .font(WinnowTypography.label)
                        .foregroundStyle(Color.winnowText)
                        .lineLimit(1)
                    Text("\(p.carrier) · \(p.status.label)")
                        .font(WinnowTypography.meta)
                        .foregroundStyle(Color.winnowTextTertiary)
                }

                Spacer()

                if p.status == .outForDelivery {
                    Text("Today")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.winnowSuccess)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.winnowSuccess.opacity(0.1))
                        .cornerRadius(WinnowRadius.pill)
                }
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
}

private struct BillCard: View {
    let thread: MailThread

    private var bill: IntelligenceResult.BillInfo? {
        for result in thread.intelligenceResults {
            if case .bill(let info) = result { return info }
        }
        return nil
    }

    var body: some View {
        if let b = bill {
            HStack(spacing: 14) {
                Image(systemName: "repeat")
                    .font(.system(size: 16))
                    .foregroundStyle(b.hasPriceChange ? Color.winnowCaution : Color.winnowTextTertiary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(b.merchant)
                        .font(WinnowTypography.label)
                        .foregroundStyle(Color.winnowText)

                    HStack(spacing: 4) {
                        Text("\(b.currency == "GBP" ? "£" : "$")\(String(format: "%.0f", b.amount))/mo")
                            .font(WinnowTypography.meta)
                            .foregroundStyle(b.hasPriceChange ? Color.winnowCaution : Color.winnowTextTertiary)

                        if b.hasPriceChange, let prev = b.previousAmount {
                            Text("(was \(b.currency == "GBP" ? "£" : "$")\(String(format: "%.0f", prev)))")
                                .font(WinnowTypography.meta)
                                .foregroundStyle(Color.winnowCaution)
                        }
                    }
                }

                Spacer()

                if let due = b.dueDate {
                    Text("in \(Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0)d")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.winnowCaution)
                }
            }
            .padding(WinnowSpacing.cardH)
            .background(
                RoundedRectangle(cornerRadius: WinnowRadius.card)
                    .fill(Color.winnowSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: WinnowRadius.card)
                            .strokeBorder(b.hasPriceChange ? Color.winnowCaution.opacity(0.2) : Color.black.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }
}
