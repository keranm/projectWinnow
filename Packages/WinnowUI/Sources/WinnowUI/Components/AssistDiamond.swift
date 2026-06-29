import SwiftUI

/// The product's signature mark. Appears wherever on-device intelligence surfaces a result.
/// A filled square rotated 45° in accent blue.
public struct AssistDiamond: View {
    public enum Size {
        case small, medium, large
        var points: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 10
            }
        }
    }

    let size: Size

    public init(size: Size = .medium) {
        self.size = size
    }

    public var body: some View {
        Rectangle()
            .fill(Color.winnowAccent)
            .frame(width: size.points, height: size.points)
            .rotationEffect(.degrees(45))
            .cornerRadius(1.5)
    }
}
