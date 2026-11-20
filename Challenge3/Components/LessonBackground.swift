import SwiftUI

/// Shared background and navigation styling for lesson screens.
struct LessonBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.background.ignoresSafeArea())
            .foregroundStyle(Palette.cream)
            .navigationBarTitleDisplayMode(.inline)
    }
}
