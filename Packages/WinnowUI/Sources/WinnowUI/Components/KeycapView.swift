import SwiftUI

/// Renders a keyboard shortcut indicator in the style of the design spec.
/// SF Mono 11pt, white background, 1px border with heavier bottom edge, radius 6.
public struct KeycapView: View {
    let label: String

    public init(_ label: String) {
        self.label = label
    }

    public var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .regular, design: .monospaced))
            .foregroundStyle(Color.winnowTextSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.winnowSurface)
            .overlay(
                RoundedRectangle(cornerRadius: WinnowRadius.keycap)
                    .strokeBorder(Color.black.opacity(0.14), lineWidth: 1)
            )
            .overlay(alignment: .bottom) {
                RoundedRectangle(cornerRadius: WinnowRadius.keycap)
                    .strokeBorder(Color.black.opacity(0.14), lineWidth: 2)
                    .frame(height: 4)
            }
            .cornerRadius(WinnowRadius.keycap)
    }
}
