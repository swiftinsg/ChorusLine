// Import SwiftUI for ViewModifier and the styling modifiers used below.
import SwiftUI

// Reusing one modifier keeps the look of all lesson screens consistent.
/// Shared background and navigation styling for lesson screens.
struct LessonBackground: ViewModifier {
    // SwiftUI calls this method to apply the styling to the wrapped content.
    func body(content: Content) -> some View {
        // Start from the original view supplied by the caller.
        content
            // Stretch the content to fill all available width and height.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Paint the palette background behind everything, including safe-area edges.
            .background(Palette.background.ignoresSafeArea())
            // Set the default foreground color for text and symbols to the theme's contrast color.
            .foregroundStyle(Palette.cream)
            // Show the navigation title in the compact inline style rather than a large title.
            .navigationBarTitleDisplayMode(.inline)
    }
}
