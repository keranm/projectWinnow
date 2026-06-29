import SwiftUI
import WinnowUI

struct EmptySelectionView: View {
    var body: some View {
        VStack(spacing: 12) {
            AssistDiamond(size: .large)

            Text("Select a thread")
                .font(WinnowTypography.body)
                .foregroundStyle(Color.winnowTextTertiary)

            HStack(spacing: 6) {
                KeycapView("J")
                Text("next")
                    .font(WinnowTypography.meta)
                    .foregroundStyle(Color.winnowTextTertiary)
                KeycapView("K")
                Text("previous")
                    .font(WinnowTypography.meta)
                    .foregroundStyle(Color.winnowTextTertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.winnowSurface)
    }
}
