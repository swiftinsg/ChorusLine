// SwiftUI provides the Color type used by every palette entry.
import SwiftUI
// UIKit is only available on some platforms, so guard its import with a compiler check.
#if canImport(UIKit)
// UIKit supplies UIColor, which can resolve light and dark variants at runtime.
import UIKit
// End of the UIKit-only import.
#endif

// One shared namespace keeps colors consistent across every lesson screen.
/// Colours used throughout Chorus Line, adapting to light and dark mode.
enum Palette {
    // A fixed blue accent that stays the same in both light and dark mode.
    /// The main blue accent used by every lesson, quiz and control.
    static let accent = Color(red: 0.33, green: 0.62, blue: 1.0)
    // A warm gold reserved for the sandbox so it cannot be confused with the blue accent.
    /// Reserved for the sandbox so it stays distinct.
    static let gold = Color(red: 0.92, green: 0.72, blue: 0.36)

    // Ask the helper for a background color that adapts to the system appearance.
    /// App background.
    static let background = dynamic(
        // Nearly white with a cool blue tint for light mode.
        light: .init(red: 0.96, green: 0.97, blue: 1.0, alpha: 1),
        // Deep navy for dark mode to reduce eye strain.
        dark: .init(red: 0.043, green: 0.06, blue: 0.12, alpha: 1)
    )

    // Cards need a surface that adapts, so use the same dynamic helper.
    /// Card and surface background.
    static let panel = dynamic(
        // Pure white panels in light mode for clear contrast with the background.
        light: .init(white: 1.0, alpha: 1),
        // Dark slate panels in dark mode to stay distinct from the background.
        dark: .init(red: 0.1, green: 0.14, blue: 0.24, alpha: 1)
    )

    // Text color flips between dark and light so it remains readable on each surface.
    /// Primary foreground/text color.
    static let cream = dynamic(
        // Almost-black ink for text in light mode.
        light: .init(red: 0.08, green: 0.10, blue: 0.16, alpha: 1),
        // Near-white ink for text in dark mode.
        dark: .init(red: 0.93, green: 0.95, blue: 1.0, alpha: 1)
    )

    // Grouped controls use a gentle tint that also adapts to light and dark mode.
    /// Subtle surface used for grouped controls.
    static let subtle = dynamic(
        // Pale blue-gray in light mode for a soft grouped look.
        light: .init(red: 0.90, green: 0.93, blue: 0.98, alpha: 1),
        // Very dark blue-gray in dark mode for the same visual role.
        dark: .init(red: 0.08, green: 0.11, blue: 0.18, alpha: 1)
    )

    // Secondary text can rely on the system's built-in muted color.
    /// Muted secondary text.
    static let muted = Color.secondary

    // Central helper that wraps a light and a dark UIColor into one adaptive SwiftUI Color.
    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        // On Apple mobile platforms, UIKit is available and supports trait-based colors.
        #if canImport(UIKit)
        // Create a SwiftUI Color from a UIColor that resolves using the current traits.
        Color(UIColor { traits in
            // Choose the dark variant only when the system interface style is dark.
            traits.userInterfaceStyle == .dark ? dark : light
        })
        // On macOS, AppKit provides the equivalent appearance-driven color API.
        #elseif canImport(AppKit)
        // NSColor with no name acts as a dynamic color resolved by the current appearance.
        Color(NSColor(name: nil) { appearance in
            // Match the appearance against darkAqua and pick the appropriate variant.
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
        // On platforms without either framework, there is no appearance to react to.
        #else
        // Fall back to the light color as a safe default.
        Color(light)
        // End of the platform-specific dynamic color selection.
        #endif
    }
}
