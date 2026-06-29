import SwiftUI

public enum WinnowTypography {
    public static let display = Font.system(size: 30, weight: .semibold).monospacedDigit()
    public static let title = Font.system(size: 22, weight: .semibold)
    public static let body = Font.system(size: 14, weight: .regular)
    public static let label = Font.system(size: 13, weight: .medium)
    public static let sectionHeader = Font.system(size: 11, weight: .semibold)
    public static let meta = Font.system(size: 11, weight: .regular).monospaced()

    // Thread list specific
    public static let senderName = Font.system(size: 13.5, weight: .semibold)
    public static let messageSubject = Font.system(size: 13, weight: .medium)
    public static let messagePreview = Font.system(size: 12.5, weight: .regular)
}

public extension View {
    func winnowSectionHeader() -> some View {
        self
            .font(WinnowTypography.sectionHeader)
            .textCase(.uppercase)
            .tracking(0.7)
            .foregroundStyle(Color.winnowTextTertiary)
    }
}
