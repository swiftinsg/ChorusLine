import SwiftUI

/// The main call-to-action button used throughout the lessons.
struct PrimaryAction: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.headline).frame(maxWidth: .infinity).padding(17)
                .background(Palette.gold, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(Palette.background)
        }
    }
}
