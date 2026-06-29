import SwiftUI
import WinnowUI

struct ConnectAccountView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 32) {
            // Logo area
            VStack(spacing: 12) {
                AssistDiamond(size: .large)
                    .scaleEffect(2)

                Text("Winnow")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.winnowText)
                    .tracking(-0.6)

                Text("Quiet, local-first email")
                    .font(WinnowTypography.body)
                    .foregroundStyle(Color.winnowTextTertiary)
            }

            // Privacy statement
            VStack(alignment: .leading, spacing: 10) {
                privacyRow(icon: "lock.fill",
                           text: "Your email never leaves your device")
                privacyRow(icon: "key.fill",
                           text: "OAuth tokens stored in your Keychain")
                privacyRow(icon: "network.slash",
                           text: "No Winnow servers — requests go straight to Gmail")
            }
            .padding(WinnowSpacing.cardH)
            .background(
                RoundedRectangle(cornerRadius: WinnowRadius.card)
                    .fill(Color.winnowStage)
            )

            // Connect button
            VStack(spacing: 10) {
                Button(action: { Task { await appState.signInWithGmail() } }) {
                    HStack(spacing: 8) {
                        if appState.isLoading {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Image(systemName: "envelope.badge")
                        }
                        Text(appState.isLoading ? "Connecting…" : "Connect Gmail")
                    }
                    .frame(minWidth: 200)
                }
                .buttonStyle(WinnowPrimaryButton())
                .disabled(appState.isLoading)

                if let error = appState.syncError {
                    Text(error)
                        .font(WinnowTypography.meta)
                        .foregroundStyle(Color.winnowAlert)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }

                Text("Your browser will open for Google sign-in.")
                    .font(WinnowTypography.meta)
                    .foregroundStyle(Color.winnowTextTertiary)
            }
        }
        .padding(WinnowSpacing.sectionHWide)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.winnowSurface)
    }

    private func privacyRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.winnowAccent)
                .frame(width: 18)
            Text(text)
                .font(WinnowTypography.label)
                .foregroundStyle(Color.winnowTextSecondary)
        }
    }
}
