// -----------------------------------------------------------------------------
// FILE SUMMARY — Components/Vinyl.swift
// -----------------------------------------------------------------------------
// PURPOSE: Reusable record graphic used throughout the app, with optional spin
//          and needle-drop animations.
//
// HOW IT WORKS:
//   • body — stacks a grey rim, black disc, seven grooves, an optional rim mark,
//     a gradient label and a centre dot; scales/offsets from a raised pose into
//     place, adds a coloured glow and starts spinning on appear when requested.
//   • onChange(of:spinning) — replays the drop and either restarts the spin loop
//     or resets rotation to zero when spinning is turned off.
//   • start() — animates rotation from 0 to 360° forever with a linear,
//     non-reversing animation.
// -----------------------------------------------------------------------------

// Import SwiftUI for shapes, animations and the view modifiers used to draw the record.
import SwiftUI

// A reusable record graphic that can spin to signal that a module has been completed.
/// A record that can spin to show that a module has been completed.
/// - `spinning`: continuously rotates the record (used for loading/completion states).
/// - `showsRimMark`: adds a visible edge highlight so rotation is easier to perceive.
/// - Local animation state (`dropped`, `rotation`) handles the "needle drop" and spin effects.
struct Vinyl: View {
    // Tint for the label and rim highlight, defaulting to the app accent.
    var color: Color = Palette.accent
    // When true, the record rotates continuously to show activity or completion.
    var spinning = false
    // Diameter of the record in points; all other sizes scale from this value.
    var size: CGFloat = 132
    // Controls whether the small center spindle dot is drawn.
    var showCenterDot = true
    // Controls whether a rim highlight is drawn to make the rotation easier to see.
    var showsRimMark = false
    // Controls whether the colored glow behind the record is shown.
    var showsGlow = true
    // Local rotation angle in degrees, driven by the repeating animation.
    @State private var rotation = 0.0
    // Tracks whether the drop-in animation has finished so the record can settle.
    @State private var dropped = false
    // Layer the record's grooves, label and spindle into a single view.
    var body: some View {
        // Stack every part of the record on top of one another.
        ZStack {
            // Draw a slightly oversized gray ring to suggest the record's outer edge.
            Circle().fill(Color.gray.opacity(0.35)).padding(-5)
            // Draw the black vinyl surface that forms the body of the record.
            Circle().fill(Color.black)
            // Add seven concentric grooves to make the disc look like a real record.
            ForEach(0..<7, id: \.self) { i in
                // Stroke each groove in faint white so it reads as a reflective ring.
                Circle().stroke(Color.white.opacity(0.055), lineWidth: 1)
                    // Push each successive groove further inward using the loop index.
                    .padding(CGFloat(i) * 8 + 7)
            }
            // Optionally draw a short colored mark near the rim to reveal the spin.
            if showsRimMark {
                // A short highlight on the outer edge makes the spin easy to see
                // without adding a marker dot.
                Circle().trim(from: 0, to: 0.08)
                    // Stroke only the trimmed arc with a rounded, colored line.
                    .stroke(color.opacity(0.95), style: StrokeStyle(lineWidth: max(5, size * 0.03), lineCap: .round))
                    // Inset the arc slightly so it sits in the outer groove area.
                    .padding(size * 0.07)
                    // Rotate the arc to the top of the record so it is easy to spot.
                    .rotationEffect(.degrees(-90))
            }
            // Draw the colorful center label using the module's chosen color.
            Circle().fill(color.gradient).padding(size * 0.29)
            // Add a thin white ring around the label for definition.
            Circle().stroke(.white.opacity(0.25), lineWidth: 1).padding(size * 0.33)
            // Optionally draw the small cream spindle dot at the very center.
            if showCenterDot { Circle().fill(Palette.cream).frame(width: 9, height: 9) }
        }
        // Constrain the stacked shapes to the requested square size.
        .frame(width: size, height: size)
        // Rotate the whole record by the current angle stored in state.
        .rotationEffect(.degrees(rotation))
        // Start slightly enlarged, then spring down to full size when dropped.
        .scaleEffect(dropped ? 1 : 1.12)
        // Start slightly raised, then drop into the final position.
        .offset(y: dropped ? 0 : -13)
        // Show a soft colored glow unless the caller disables it.
        .shadow(color: showsGlow ? color.opacity(0.25) : .clear, radius: 16)
        // Kick off the entrance and spinning animations when the record first appears.
        .onAppear {
            // Spring the record down from its raised pose for a satisfying arrival.
            withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) { dropped = true }
            // Begin continuous rotation only if this record is meant to spin.
            if spinning { start() }
        }
        // React when the spinning flag is toggled from outside.
        .onChange(of: spinning) { _, value in
            // Replay the drop so the change is visually noticeable.
            dropped = false
            // Spring the record back down after resetting the pose.
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) { dropped = true }
            // Restart the loop when spinning turns on, or reset the angle when it turns off.
            if value { start() } else { rotation = 0 }
        }
    }
    // Begin a linear, endless rotation from zero to a full turn.
    private func start() {
        // Reset to zero so every start begins from the same orientation.
        rotation = 0
        // Animate one full revolution repeatedly without reversing direction.
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) { rotation = 360 }
    }
}
