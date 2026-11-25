// -----------------------------------------------------------------------------
// FILE SUMMARY — Views/DrumLessonView.swift
// -----------------------------------------------------------------------------
// PURPOSE: Module 3 wrapper: rhythm slides followed by the beat machine.
//
// HOW IT WORKS:
//   • body — shows DrumPadsView once `showPads` is true; before that it presents
//     two LessonSlides about rhythm and pop grooves, with `onFinish` revealing
//     the playable pads.
// -----------------------------------------------------------------------------

// Import SwiftUI for the View protocol, state wrappers, and environment object support.
import SwiftUI

/// Module 3: introduces rhythm, then opens the drum pads.
// Module 3's flow: teach rhythm concepts in slides, then reveal the playable drum pads.
struct DrumLessonView: View {
    // Read the shared app state so it can be passed to the drum pads and to configure the swipe hint.
    @EnvironmentObject var state: StudioState
    // Controls the screen: false shows slides, true shows the beat machine.
    @State private var showPads = false
    // The two lesson cards covering rhythm basics and pop groove exploration.
    private let slides = [
        // First card explains the drum's role and the sounds of kick, snare, and hi-hat.
        LessonSlide(title: "Rhythm is the heartbeat", description: "A drum beat sets the pulse and energy of a song. Kick drums create the low thump, snares add a sharp backbeat, and hi-hats mark smaller subdivisions."),
        // Second card lists groove styles and invites the learner to audition each pad.
        LessonSlide(title: "Explore pop grooves", description: "Classic pop, dance pop, synth pop, pop rock, pop ballad and R&B pop use different patterns. Tap each pad to hear its rhythm and discover what fits your song.")
    ]
    // Switches between the slideshow and the drum pads depending on lesson progress.
    var body: some View {
        // If the learner finished the slides, present the interactive beat machine.
        if showPads {
            // Pass the shared state into DrumPadsView so selections and completion are tracked.
            DrumPadsView().environmentObject(state)
        } else {
            // Otherwise show the slides with the module title, accent color, and optional swipe hint.
            LessonSlideshow(moduleTitle: "DRUM BEATS", accent: Palette.accent, slides: slides, showsSwipeHint: state.showModuleSpinHint) {
                // When the final swipe completes, flip the flag to replace slides with the pads.
                showPads = true
            }
        }
    }
}
