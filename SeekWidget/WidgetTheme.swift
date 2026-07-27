import SwiftUI

/// Widget-local color helpers. The app target has its own `Color(hex:)` in
/// ContentView.swift; this is a separate copy for the widget extension target
/// (which doesn't compile the app's sources). Kept byte-for-byte in sync with
/// docs/design-system.md.
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

enum WidgetTheme {
    static let gold = Color(hex: "CDA349")
    static let sage = Color(hex: "5B7B5E")
    static let background = Color(hex: "FAFAF6")
    static let surface = Color(hex: "FFFFFF")
    static let textPrimary = Color(hex: "1A1A1A")
    static let textSecondary = Color(hex: "6B7280")
}
