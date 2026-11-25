// -----------------------------------------------------------------------------
// FILE SUMMARY — Components/RecordPlayerBadge.swift
// -----------------------------------------------------------------------------
// PURPOSE: Miniature turntable icon shown on the home menu for completed modules.
//
// HOW IT WORKS:
//   • body — overlays a gradient platter, a spinning mini Vinyl and a drawn
//     tonearm; on appear the record springs from a raised, smaller pose onto the
//     deck.
//   • tonearm — private view drawing the bent arm, pivot and highlight dot as a
//     Path plus circles sized relative to the badge.
// -----------------------------------------------------------------------------

// Import SwiftUI for the shapes, gradients and layout used in the miniature turntable.
import SwiftUI

// A compact turntable icon signals at a glance that a module has been completed.
/// A top-down miniature turntable used to mark a completed module on the menu.
/// The record "drops" onto the platter on appear to mirror the completion animation.
struct RecordPlayerBadge: View {
    // Record color matched to the finished module.
    let color: Color
    // Overall badge size, defaulting to 100 points.
    var size: CGFloat = 100
    // Accent color for the platter outline and tonearm.
    var accent: Color = Palette.accent
    // Tracks whether the record's drop-in animation has started.
    @State private var dropped = false

    // Compose the platter, record and tonearm into one badge.
    var body: some View {
        // Overlay the record and tonearm without a platter background.
        ZStack {
            // Place a spinning miniature record.
            Vinyl(color: color, spinning: true, size: size * 0.82, showCenterDot: true, showsGlow: false)
                // Animate from a small scale to full size once the badge appears.
                .scaleEffect(dropped ? 1 : 0.55)
                // Drop the record downward into place at the same time.
                .offset(y: dropped ? 0 : -size * 0.16)

            // Draw the tonearm above the record so it visually rests on the vinyl.
            tonearm
        }
        // Constrain the whole badge to a square of the requested size.
        .frame(width: size, height: size)
        // Start the drop animation when the badge first joins the view hierarchy.
        .onAppear {
            // Spring to the settled pose so the record appears to fall onto the deck.
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) { dropped = true }
        }
    }

    // Build the needle arm and its pivot as a separate private view for clarity.
    private var tonearm: some View {
        // Layer the arm, pivot and highlight dot on top of one another.
        ZStack {
            // Draw the bent arm with a SwiftUI Path using fractions of the badge size.
            Path { path in
                // Start at the pivot in the top-right corner.
                path.move(to: CGPoint(x: size * 0.85, y: size * 0.14))
                // Angle the arm down toward the middle of the record.
                path.addLine(to: CGPoint(x: size * 0.75, y: size * 0.30))
                // End the arm where the needle would touch the vinyl.
                path.addLine(to: CGPoint(x: size * 0.68, y: size * 0.52))
            }
            // Stroke the path with a rounded accent line scaled to the badge size.
            .stroke(accent, style: StrokeStyle(lineWidth: max(2, size * 0.028), lineCap: .round, lineJoin: .round))

            // Draw the round pivot base at the arm's starting point.
            Circle()
                // Fill it with dark gray to suggest metal.
                .fill(Color(white: 0.2))
                // Size the pivot relative to the badge.
                .frame(width: size * 0.14, height: size * 0.14)
                // Outline the pivot with a translucent accent ring.
                .overlay {
                    Circle().stroke(accent.opacity(0.5), lineWidth: max(1, size * 0.012))
                }
                // Position the pivot where the path begins.
                .position(x: size * 0.85, y: size * 0.14)

            // Draw a small white cap on the pivot as a highlight.
            Circle()
                // Fill it with white so it stands out from the dark base.
                .fill(Color.white)
                // Keep it at least 5 points wide even on small badges.
                .frame(width: max(5, size * 0.06), height: max(5, size * 0.06))
                // Place the cap exactly on top of the pivot.
                .position(x: size * 0.85, y: size * 0.14)
        }
    }
}
