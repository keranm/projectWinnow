import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(WinnowSettings.self) private var settings

    var body: some View {
        Group {
            if !appState.isAuthenticated {
                ConnectAccountView()
                    .frame(minWidth: 500, minHeight: 400)
            } else {
                mainLayout
            }
        }
        .task { await appState.bootstrap() }
    }

    private var mainLayout: some View {
        @Bindable var state = appState
        return HStack(spacing: 0) {
            SidebarView()
                .frame(width: 220)
                .ignoresSafeArea()
            Divider()
                .ignoresSafeArea()
            detailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .sheet(isPresented: $state.isComposing) {
            ComposeView(isPresented: $state.isComposing)
                .environment(appState)
                .environment(settings)
        }
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
