import SwiftUI
import WinnowUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 212, ideal: 220, max: 228)
        } detail: {
            detailContent
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Winnow")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.winnowTextTertiary)
            }
        }
        .background(Color.winnowStage)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch appState.selectedNavItem {
        case .today:
            TodayView()
        default:
            MailContentView()
        }
    }
}
