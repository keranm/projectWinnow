import SwiftUI

public extension Color {
    // MARK: - Text
    static let winnowText = Color(hex: "1C1C20")
    static let winnowTextSecondary = Color(hex: "55555C")
    static let winnowTextTertiary = Color(hex: "9A9AA0")

    // MARK: - Backgrounds
    static let winnowSidebar = Color(hex: "FAFAFA")
    static let winnowSurface = Color(hex: "FFFFFF")
    static let winnowStage = Color(hex: "ECECED")

    // MARK: - Accent
    static let winnowAccent = Color(hex: "2F6BDB")
    static let winnowAccentTint = Color(hex: "EEF3FC")

    // MARK: - Semantic
    static let winnowSuccess = Color(hex: "2F9E6F")
    static let winnowCaution = Color(hex: "C08A4A")
    static let winnowAlert = Color(hex: "D9534F")

    // MARK: - Controls
    static let winnowToggleOff = Color(hex: "D8D8DE")
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
