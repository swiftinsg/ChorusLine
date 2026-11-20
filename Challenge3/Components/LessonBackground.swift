import SwiftUI

/// Shared background and navigation styling for lesson screens.
struct LessonBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.background(Palette.background).foregroundStyle(Palette.cream)
            .navigationBarTitleDisplayMode(.inline)
    }
}
