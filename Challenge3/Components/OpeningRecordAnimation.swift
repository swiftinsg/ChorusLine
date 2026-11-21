// Import SwiftUI for View, GeometryReader and the animation modifiers used here.
import SwiftUI

// This full-screen transition turns a loading moment into a record-unveiling animation.
/// Transition shown while a module is opening.
struct OpeningRecordAnimation: View {
    // Color of the record, matched to the module being opened.
    let color: Color
    // Animation phase: 0 is the small start pose, later values are the grown, rotated pose.
    let stage: Int
    // Accent color used for the loading label, defaulting to the app accent.
    var accent: Color = Palette.accent
    // Build the transition view using the available screen size.
    var body: some View {
        // GeometryReader supplies the container size so the record scales to any device.
        GeometryReader { geo in
            // Base record size never exceeds 210 points and shrinks on smaller screens.
            let baseSize = min(210, min(geo.size.width, geo.size.height) * 0.4)
            // Compute the growth factor, clamped between 0.85 and 1.25 for a pleasant reveal.
            let maxScale = min(1.25, max(0.85, (geo.size.height * 0.36) / max(baseSize, 1)))
            // Reserve a frame large enough for the scaled record without clipping its glow.
            let vinylArea = baseSize * max(maxScale, 0.48)
            // Layer the dimming background behind the text and record.
            ZStack {
                // Cover the screen with a nearly opaque background to hide the previous view.
                Palette.background.opacity(0.97).ignoresSafeArea()
                // Stack the label, record and caption vertically with generous spacing.
                VStack(spacing: 36) {
                    // Announce that the lesson content is being prepared.
                    Text("NOW LOADING")
                        // Use a headline font so the announcement stands out.
                        .font(.headline)
                        // Add wide letter spacing for a stylized, technical look.
                        .tracking(4)
                        // Tint the label with this module's accent color.
                        .foregroundStyle(accent)
                    // Draw the spinning record at the computed base size.
                    Vinyl(color: color, spinning: true, size: baseSize)
                        // Start small for stage 0, then grow to the computed scale.
                        .scaleEffect(stage == 0 ? 0.48 : maxScale)
                        // Rotate the grown record into place for a dramatic reveal.
                        .rotationEffect(.degrees(stage == 0 ? 0 : 110))
                        // Add a soft colored glow that reinforces the module color.
                        .shadow(color: color.opacity(0.5), radius: 30)
                        // Constrain layout to the reserved area so surrounding views stay put.
                        .frame(width: vinylArea, height: vinylArea)
                    // Give the user a friendly hint about what is happening.
                    Text("Dropping the needle…")
                        // Use the standard foreground color so secondary text stays readable.
                        .foregroundStyle(Palette.cream)
                }
                // Add side margins so text does not touch the screen edges.
                .padding(.horizontal, 24)
                // Let the stack fill the entire available space.
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
