import SwiftUI

/// A panel containing a lesson heading and its explanation.
/// Used by `LessonSlideshow` to present each lesson slide's content consistently.
struct LessonCard: View {
    let title: String
    let description: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title2.bold()).foregroundStyle(Palette.accent)
            Text(description).font(.body).foregroundStyle(Palette.cream)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(Palette.panel, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Palette.cream.opacity(0.08), lineWidth: 1)
        }
    }
}
