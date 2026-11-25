// -----------------------------------------------------------------------------
// FILE SUMMARY — Components/RecordPlayerCompletion.swift
// -----------------------------------------------------------------------------
// PURPOSE: Full-screen celebration after a module is completed: a record drops
//          onto a top-down turntable and starts spinning.
//
// HOW IT WORKS:
//   • body — sizes the deck to the screen with GeometryReader, then layers a
//     dimmed background with the headline, metallic deck/platter/record/tonearm
//     and a status caption. Stage 0 is the high drop pose, stage 1 settles the
//     record, stage 2 spins it and shows the final message.
// -----------------------------------------------------------------------------

// Import SwiftUI for GeometryReader, shapes and the layout modifiers used in the scene.
import SwiftUI

// A record drops onto a turntable seen from directly above when a module is finished.
// Animate the phases from a high drop pose to a settled, spinning record.
struct RecordPlayerCompletion: View {
    // Record color taken from the completed module.
    let color: Color
    // Animation phase: 0 is high above, 1 is settling, 2 is spinning in place.
    let stage: Int
    // Accent color for the deck outline and tonearm.
    var accent: Color = Palette.accent

    // Build the completion scene sized to the current screen.
    var body: some View {
        // GeometryReader provides screen dimensions so the deck fits on any device.
        GeometryReader { geometry in
            // Shrink the deck on short screens so the text and deck both remain visible.
            // Scale the turntable so the whole completion scene fits on screen.
            let deckWidth = max(170.0, min(geometry.size.width - 36,
                                              340.0,
                                              (geometry.size.height - 300) / 0.90))
            // Layer the dimmed background behind the text and turntable.
            ZStack {
                // Fade the previous screen behind a nearly opaque app background.
                Palette.background.opacity(0.97).ignoresSafeArea()
                // Stack the headline, deck and status text vertically.
                VStack(spacing: 24) {
                    // Celebrate the finished module with a bold accented headline.
                    Text("MODULE COMPLETE!")
                        // Emphasize the message and color it with the accent.
                        .font(.title2.bold()).foregroundStyle(accent)

                    // Layer the platter, record and tonearm into one top-down deck.
                    ZStack {
                        // Draw the square deck with rounded corners.
                        RoundedRectangle(cornerRadius: deckWidth * 0.08)
                            // Fill it with a metallic gradient for a realistic surface.
                            .fill(LinearGradient(colors: [Color(white: 0.31), Palette.panel, Color(white: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            // Outline the deck with a translucent accent border.
                            .overlay {
                                // Match the outline's corner radius to the deck itself.
                                RoundedRectangle(cornerRadius: deckWidth * 0.08)
                                    // Stroke with the accent so the deck edge stands out.
                                    .stroke(accent.opacity(0.55), lineWidth: 2)
                            }
                            // Drop a shadow to lift the deck off the background.
                            .shadow(color: .black.opacity(0.7), radius: 16, y: 10)

                        // Draw the dark circular platter that holds the record.
                        Circle().fill(Color(white: 0.055))
                            // Size the platter relative to the deck.
                            .frame(width: deckWidth * 0.77, height: deckWidth * 0.77)
                            // Add a subtle gray rim to give the platter depth.
                            .overlay {
                                Circle().stroke(Color.gray.opacity(0.7), lineWidth: max(3, deckWidth * 0.014))
                            }
                            // Nudge the platter left and up to leave room for the tonearm.
                            .offset(x: -deckWidth * 0.035, y: -deckWidth * 0.03)

                        // Add the record last so it sits on top of the platter.
                        // Viewed from above, the record simply settles down onto
                        // the platter instead of sliding in from the side.
                        Vinyl(color: color, spinning: stage == 2, size: deckWidth * 0.66)
                            // Shrink from the drop pose to the final size as stages advance.
                            .scaleEffect(stage == 0 ? 1.30 : stage == 1 ? 1.08 : 1)
                            // Align the record with the platter underneath it.
                            .offset(x: -deckWidth * 0.035, y: -deckWidth * 0.03)
                            // Reduce the shadow once the record has landed flat on the deck.
                            .shadow(color: .black.opacity(0.65), radius: stage == 2 ? 2 : 26, y: stage == 2 ? 1 : 12)

                        // Tonearm rests over the top-right of the deck.
                        Path { path in
                            // Start the arm at its pivot in the top-right.
                            path.move(to: CGPoint(x: deckWidth * 0.84, y: deckWidth * 0.17))
                            // Bend the arm toward the center of the record.
                            path.addLine(to: CGPoint(x: deckWidth * 0.73, y: deckWidth * 0.30))
                            // End the arm where the needle would touch the vinyl.
                            path.addLine(to: CGPoint(x: deckWidth * 0.65, y: deckWidth * 0.50))
                        }
                        // Stroke the arm with a rounded accent line sized to the deck.
                        .stroke(accent, style: StrokeStyle(lineWidth: max(4, deckWidth * 0.02), lineCap: .round, lineJoin: .round))
                        // Mark the pivot with a small white dot.
                        Circle().fill(Color.white)
                            // Keep the dot visible even on smaller decks.
                            .frame(width: max(10, deckWidth * 0.047), height: max(10, deckWidth * 0.047))
                            // Place the dot exactly at the arm's pivot point.
                            .position(x: deckWidth * 0.84, y: deckWidth * 0.17)
                    }
                    // Give the turntable a square frame matching its computed size.
                    .frame(width: deckWidth, height: deckWidth)

                    // Show a final message once the record has fully loaded.
                    Text(stage == 2 ? "Record loaded. Keep creating!" : "Loading your record…")
                        // Use the theme's foreground color for readable status text.
                        .foregroundStyle(Palette.cream)
                }
                // Let the stack occupy the whole screen.
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
