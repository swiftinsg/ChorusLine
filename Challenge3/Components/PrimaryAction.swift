import SwiftUI

/// The main call-to-action button used throughout the lessons.
/// `tint` allows modules like the sandbox to use a distinct accent color.
struct PrimaryAction: View {
    let title: String
    var tint: Color = Palette.accent
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.headline).frame(maxWidth: .infinity).padding(17)
                .background(tint, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}
