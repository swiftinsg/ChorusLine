// Import SwiftUI for ViewModifier, DragGesture and the geometry types used here.
import SwiftUI

// Measures actual angular movement around the center of the vinyl.
// Clockwise turns are positive in screen coordinates (y increases downwards).
// Converting continuous rotation into steps lets a scrubber advance one item at a time.
struct CircularVinylGesture: ViewModifier {
    // The record's diameter, used to find its center and ignore drags near the middle.
    let diameter: CGFloat
    // Callback invoked with +1 or -1 whenever a full step of rotation accumulates.
    let onStep: (Int) -> Void
    // Remember the previous drag angle so each movement can be compared against it.
    @State private var previousAngle: Double? = nil
    // Keep a running angle total until it reaches one 65-degree step threshold.
    @State private var accumulated = 0.0
    // Build the modified view and attach the rotation-detecting drag gesture.
    func body(content: Content) -> some View {
        // Make the whole circular area respond to touches, not just the drawn pixels.
        content.contentShape(Circle())
            // Recognize drags of at least 3 points, measured in the view's own coordinate space.
            .gesture(DragGesture(minimumDistance: 3, coordinateSpace: .local)
                // Run this closure repeatedly as the finger moves around the record.
                .onChanged { value in
                    // Treat the center of the vinyl as the origin for angle calculations.
                    let center = CGPoint(x: diameter / 2, y: diameter / 2)
                    // Horizontal offset of the finger from the center.
                    let x = value.location.x - center.x
                    // Vertical offset of the finger; positive values go downward on screen.
                    let y = value.location.y - center.y
                    // Ignore movement too close to the spindle, where angles would jump erratically.
                    guard hypot(x, y) > diameter * 0.15 else { return }
                    // Convert the offset to degrees; atan2 makes clockwise turns positive here.
                    let angle = atan2(y, x) * 180 / .pi
                    // Only measure a difference once we have an earlier angle to compare with.
                    if let previousAngle {
                        // Difference between this angle and the previous sample.
                        var delta = angle - previousAngle
                        // Unwrap a +179 to -179 jump so it counts as a small clockwise turn.
                        if delta > 180 { delta -= 360 }
                        // Unwrap a -179 to +179 jump the same way for counterclockwise turns.
                        if delta < -180 { delta += 360 }
                        // Add the corrected movement to the running total.
                        accumulated += delta
                        // Emit one forward step for every full 65 degrees of clockwise rotation.
                        while accumulated >= 65 {
                            onStep(1); accumulated -= 65
                        }
                        // Emit one backward step for every full 65 degrees the other way.
                        while accumulated <= -65 {
                            onStep(-1); accumulated += 65
                        }
                    }
                    // Save this angle so the next drag change can be measured from here.
                    previousAngle = angle
                }
                // When the drag ends, discard the last angle and clear the running total.
                .onEnded { _ in previousAngle = nil; accumulated = 0 })
    }
}
