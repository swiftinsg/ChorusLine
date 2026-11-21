import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Colours used throughout Chorus Line, adapting to light and dark mode.
enum Palette {
    /// The main blue accent used by every lesson, quiz and control.
    static let accent = Color(red: 0.33, green: 0.62, blue: 1.0)
    /// Reserved for the sandbox so it stays distinct.
    static let gold = Color(red: 0.92, green: 0.72, blue: 0.36)

    /// App background.
    static let background = dynamic(
        light: .init(red: 0.96, green: 0.97, blue: 1.0, alpha: 1),
        dark: .init(red: 0.043, green: 0.06, blue: 0.12, alpha: 1)
    )

    /// Card and surface background.
    static let panel = dynamic(
        light: .init(white: 1.0, alpha: 1),
        dark: .init(red: 0.1, green: 0.14, blue: 0.24, alpha: 1)
    )

    /// Primary foreground/text color.
    static let cream = dynamic(
        light: .init(red: 0.08, green: 0.10, blue: 0.16, alpha: 1),
        dark: .init(red: 0.93, green: 0.95, blue: 1.0, alpha: 1)
    )

    /// Subtle surface used for grouped controls.
    static let subtle = dynamic(
        light: .init(red: 0.90, green: 0.93, blue: 0.98, alpha: 1),
        dark: .init(red: 0.08, green: 0.11, blue: 0.18, alpha: 1)
    )

    /// Muted secondary text.
    static let muted = Color.secondary

    /// Resolves a color appropriate for the current interface style on supported platforms.
    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        #if canImport(UIKit)
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
        #elseif canImport(AppKit)
        Color(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
        #else
        Color(light)
        #endif
    }
}
