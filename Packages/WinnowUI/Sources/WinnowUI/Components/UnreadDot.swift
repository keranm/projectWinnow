import SwiftUI

public struct UnreadDot: View {
    let isUnread: Bool

    public init(isUnread: Bool) {
        self.isUnread = isUnread
    }

    public var body: some View {
        Circle()
            .fill(isUnread ? Color.winnowAccent : Color.clear)
            .frame(width: 6, height: 6)
    }
}
