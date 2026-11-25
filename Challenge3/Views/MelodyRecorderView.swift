// -----------------------------------------------------------------------------
// FILE SUMMARY — Views/MelodyRecorderView.swift
// -----------------------------------------------------------------------------
// PURPOSE: Melody module entry screen explaining drawing-based melody creation
//          and linking to the drawing canvas.
//
// HOW IT WORKS:
//   • body — a vertical stack with the title, decorative vinyl, explanation, a
//     NavigationLink to MelodyDrawView, a landscape tip and a Done button that
//     completes module 3 and dismisses after the celebration.
// -----------------------------------------------------------------------------

// Import SwiftUI for the view hierarchy, navigation link, labels, and styling modifiers.
import SwiftUI

/// Entry point for the melody drawing experience.
// An introductory screen that explains melody drawing before navigating to the canvas, with a module completion button.
struct MelodyRecorderView: View {
    // Read the shared app state so it can be handed to the drawing screen and used to complete the module.
    @EnvironmentObject var state: StudioState
    // Access the presentation environment so the Done action can dismiss this screen after completion.
    @Environment(\.dismiss) private var dismiss

    // Build a vertical stack of title, record art, instructions, navigation, and completion controls.
    var body: some View {
        // Arrange the content with generous spacing between sections.
        VStack(spacing: 22) {
            // Show the screen title as the main heading.
            Text("MELODY")
                // Use a large bold system font to match the other module headers.
                .font(.system(size: 28, weight: .bold))
                // Add letter spacing for a stylized studio aesthetic.
                .tracking(1.5)
                // Color the title with the app's accent palette.
                .foregroundStyle(Palette.accent)
            // Decorative half-visible record reinforces the music-studio theme of the module.
            Vinyl(color: Palette.accent, size: 190)
            // Explain how drawing gestures map to musical note lengths on the canvas.
            Text("Turn your drawings into melody. Long strokes become sustained notes, and short strokes become quick notes.")
                // Mute the color so the explanation reads as supporting text.
                .foregroundStyle(Palette.muted)
                // Center multi-line text for a balanced look.
                .multilineTextAlignment(.center)

            // Navigate to the drawing canvas when the learner taps the call-to-action.
            NavigationLink {
                // Build the canvas screen and give it access to the shared app state.
                MelodyDrawView().environmentObject(state)
            } label: {
                // Combine a system brush icon with descriptive text for an obvious action.
                Label("Open Melody Canvas", systemImage: "paintbrush.pointed.fill")
                    // Stretch the button across the available width and pad it for a large tap target.
                    .frame(maxWidth: .infinity).padding(15)
                    // Fill the button with the accent color inside a rounded rectangle.
                    .background(Palette.accent, in: RoundedRectangle(cornerRadius: 14))
                    // Use white text for contrast against the accent background.
                    .foregroundStyle(.white)
            }

            // Advise the learner to rotate to landscape for the best drawing experience on the next screen.
            Text("For the best experience, hold your phone horizontally on the next page.")
                // Use small caption text so this tip stays secondary to the main instructions.
                .font(.caption).foregroundStyle(Palette.muted).multilineTextAlignment(.center)

            // Push the completion button to the bottom of the available space.
            Spacer()
            // Mark the melody module complete, then dismiss after a short delay so feedback can be seen.
            PrimaryAction(title: "Done — Complete Module") {
                // Record module 3 as finished in the shared app state.
                state.finish(3)
                // Wait briefly before dismissing so the completion animation is visible.
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { dismiss() }
            }
        }
        // Add side margins around the whole stack so content doesn't touch the screen edges.
        .padding(20)
        // Apply the shared lesson background styling behind this screen.
        .modifier(LessonBackground())
        // Hide the inherited navigation title because this screen draws its own heading.
        .navigationTitle("")
    }
}
