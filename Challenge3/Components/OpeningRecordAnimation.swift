// -----------------------------------------------------------------------------
// FILE SUMMARY — Components/OpeningRecordAnimation.swift
// -----------------------------------------------------------------------------
// PURPOSE: Seamless opening transition that flies the record from the tapped
//          home-screen card down to the bottom of the screen, expanding as it
//          travels. There is no loading screen or status text.
//
// HOW IT WORKS:
//   • body — reads the screen size, derives the destination pose used by the
//     lesson slideshow (half a record visible at the bottom edge), and places a
//     spinning Vinyl between the captured card frame and that destination.
//   • Changing `stage` from 0 to 1 animates both the position and the scale, so
//     the record grows and travels in one continuous motion.
// -----------------------------------------------------------------------------

// Import SwiftUI for View, GeometryReader and the animation modifiers used here.
import SwiftUI

// The record transitions straight from its home card to the bottom of the screen.
/// Full-screen transition that expands a module's vinyl and moves it to the bottom.
struct VinylOpenTransition: View {
    // Color of the record, matched to the module being opened.
    let color: Color
    // Frame of the record on the home card, measured in global screen coordinates.
    let startFrame: CGRect
    // Animation phase: 0 is the card pose, 1 is the expanded bottom pose.
    let stage: Int

    // Build the transition using the available screen size.
    var body: some View {
        // GeometryReader supplies the screen dimensions so the destination matches the lesson deck.
        GeometryReader { geometry in
            // LessonSlideshow lays out inside the safe area, so match its available height.
            let lessonHeight = geometry.size.height - geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom
            // Use the same record diameter as LessonSlideshow so the transition lands in place.
            let targetSize = lessonHeight * 2 / 3
            // Keep a sensible minimum size when a frame has not been measured yet.
            let startSize = max(startFrame.width, 24)
            // Start at the tapped card's record and finish centred on the slideshow's bottom edge, half visible.
            let startCenter = CGPoint(x: startFrame.midX, y: startFrame.midY)
            let targetCenter = CGPoint(x: geometry.size.width / 2,
                                       y: geometry.size.height - geometry.safeAreaInsets.bottom)
            // Draw the travelling record at its original size, then scale it into the final diameter.
            Vinyl(color: color, spinning: true, size: startSize, showsGlow: false)
                // Grow from the card artwork to the slideshow-sized record.
                .scaleEffect(stage == 0 ? 1 : targetSize / startSize)
                // Move from the card to the bottom edge of the screen.
                .position(stage == 0 ? startCenter : targetCenter)
                // Add a soft glow that grows with the record to reinforce the module color.
                .shadow(color: color.opacity(stage == 0 ? 0.2 : 0.4), radius: stage == 0 ? 8 : 24)
        }
        // Let taps pass through; HomeView already guards against opening two modules at once.
        .allowsHitTesting(false)
    }
}
