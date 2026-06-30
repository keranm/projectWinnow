import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

public extension Color {
    // MARK: - Text
    static let winnowText            = adaptive(light: "1C1C20", dark: "F2F2F5")
    static let winnowTextSubdued     = adaptive(light: "3A3A40", dark: "C0C0C8") // read-state sender names
    static let winnowTextSecondary   = adaptive(light: "55555C", dark: "A0A0A8")
    static let winnowTextTertiary    = adaptive(light: "9A9AA0", dark: "6A6A72")
    static let winnowTextQuaternary  = adaptive(light: "B2B2B8", dark: "545460") // lightest text: muted timestamps, section labels

    // MARK: - Backgrounds
    static let winnowSidebar        = adaptive(light: "FAFAFA", dark: "161617")
    static let winnowSurface        = adaptive(light: "FFFFFF", dark: "1C1C1E")
    static let winnowStage          = adaptive(light: "ECECED", dark: "0E0E10")

    // MARK: - Accent
    static let winnowAccent         = adaptive(light: "2F6BDB", dark: "4F8EF0")
    static let winnowAccentTint     = adaptive(light: "EEF3FC", dark: "20304D")

    // MARK: - Semantic
    static let winnowSuccess        = adaptive(light: "2F9E6F", dark: "3DB87F")
    static let winnowCaution        = adaptive(light: "C08A4A", dark: "D4A562")
    static let winnowAlert          = adaptive(light: "D9534F", dark: "E86560")

    // MARK: - Controls
    static let winnowToggleOff      = adaptive(light: "D8D8DE", dark: "48484A")

    // MARK: - Hex initializer
    init(hex: String) {
        let clean = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let scanner = Scanner(string: clean)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255
        )
    }
}

// Adaptive helper — avoids the NSColor/UIColor closure capture problem by
// resolving the NSColor/UIColor values before entering the dynamic-provider block.
private extension Color {
    static func adaptive(light lightHex: String, dark darkHex: String) -> Color {
        #if os(macOS)
        let light = platformColor(hex: lightHex)
        let dark  = platformColor(hex: darkHex)
        return Color(NSColor(name: nil) { $0.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light })
        #else
        let light = platformColor(hex: lightHex)
        let dark  = platformColor(hex: darkHex)
        return Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
        #endif
    }

    #if os(macOS)
    static func platformColor(hex: String) -> NSColor {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        return NSColor(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255,
            alpha: 1
        )
    }
    #else
    static func platformColor(hex: String) -> UIColor {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        return UIColor(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255,
            alpha: 1
        )
    }
    #endif
}
