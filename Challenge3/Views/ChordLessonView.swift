// -----------------------------------------------------------------------------
// FILE SUMMARY — Views/ChordLessonView.swift
// -----------------------------------------------------------------------------
// PURPOSE: Module 2 wrapper: shows chord lesson slides, then the interactive
//          chord piano.
//
// HOW IT WORKS:
//   • body — presents PianoView with the shared state once `showPiano` is true;
//     otherwise shows a LessonSlideshow with three slides (chords, progressions,
//     using the piano) whose `onFinish` flips the flag.
// -----------------------------------------------------------------------------

// Import SwiftUI for the View protocol, state wrappers, and environment object support.
import SwiftUI

/// Module 2: introduces chords and progressions, then opens the piano.
// Module 2's flow: show lesson slides first, then switch to the interactive piano when the slides finish.
struct ChordLessonView: View {
    // Read the shared app state from the environment so it can be passed to the piano and used for hint settings.
    @EnvironmentObject var state: StudioState
    // Controls which screen is visible: false shows slides, true shows the piano.
    @State private var showPiano = false
    // The three lesson cards explaining chords, progressions, and how to use the piano.
    private let slides = [
        // First card defines what a chord is and how note combinations create different feelings.
        LessonSlide(title: "What is a chord?", description: "A chord is a group of notes played together. Different combinations create different feelings."),
        // Second card explains progressions and suggests the common pop C–G–Am–F example.
        LessonSlide(title: "What is a progression?", description: "A chord progression is a sequence of chords repeated through part of a song. Try C–G–Am–F, a common pop progression."),
        // Third card teaches how to interact with the piano UI that appears next.
        LessonSlide(title: "How to use the piano", description: "Choose a progression, then tap its chord buttons to hear them. Use Play All to hear the full sequence.")
    ]
    // Switches between the slideshow and the piano depending on lesson progress.
    var body: some View {
        // If the learner finished the slides, present the interactive piano screen.
        if showPiano {
            // Pass the shared state into PianoView so chord choices and progress are remembered.
            PianoView().environmentObject(state)
        } else {
            // Otherwise show the slides with the module title and accent color, plus the optional swipe hint setting.
            LessonSlideshow(moduleTitle: "CHORD PROGRESSION", accent: Palette.chord, slides: slides, showsSwipeHint: state.showModuleSpinHint) {
                // When the final swipe completes, flip the flag to replace slides with the piano.
                showPiano = true
            }
        }
    }
}
