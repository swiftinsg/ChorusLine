// -----------------------------------------------------------------------------
// FILE SUMMARY — Components/PrimaryAction.swift
// -----------------------------------------------------------------------------
// PURPOSE: Reusable full-width call-to-action button used by lessons and sandbox.
//
// HOW IT WORKS:
//   • body — a plain Button whose label is a full-width headline on a rounded,
//     tinted background (accent by default, gold in the sandbox) with white text.
// -----------------------------------------------------------------------------

// Import SwiftUI for View, Button, Text and the layout modifiers used here.
import SwiftUI

// A reusable primary button keeps lesson calls-to-action visually consistent.
/// The main call-to-action button used throughout the lessons.
/// `tint` allows modules like the sandbox to use a distinct accent color.
struct PrimaryAction: View {
    // The label text shown on the button, supplied by the caller.
    let title: String
    // Optional tint color, defaulting to the app's accent blue.
    var tint: Color = Palette.accent
    // Closure executed when the user taps the button.
    let action: () -> Void
    // SwiftUI builds the button's view hierarchy here.
    var body: some View {
        // Wrap the custom label in a Button so taps call the stored action.
        Button(action: action) {
            // Show the title in headline type, stretch full width, and add comfortable padding.
            Text(title).font(.headline).frame(maxWidth: .infinity).padding(17)
                // Fill a rounded rectangle with the tint to form the button's background.
                .background(tint, in: RoundedRectangle(cornerRadius: 14))
                // Keep the label legible against the colored background.
                .foregroundStyle(.white)
        }
        // Remove the default button styling so only our custom appearance is visible.
        .buttonStyle(.plain)
    }
}
