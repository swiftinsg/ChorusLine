// -----------------------------------------------------------------------------
// FILE SUMMARY — Views/MelodyView.swift
// -----------------------------------------------------------------------------
// PURPOSE: Module 4 wrapper: melody-writing slides followed by the melody
//          recorder entry screen.
//
// HOW IT WORKS:
//   • body — presents MelodyRecorderView with the shared state once `recording`
//     is true; otherwise shows four LessonSlides (mood, humming, note variety,
//     capturing ideas) whose `onFinish` flips the flag.
// -----------------------------------------------------------------------------

// Import SwiftUI for the View protocol, state wrappers, and environment object support.
import SwiftUI

/// Module 4: melody tips, followed by hum recording.
// Module 4's flow: teach melody-writing ideas in slides, then open the melody recording experience.
struct MelodyView: View {
    // Read the shared app state so it can be passed to the recorder and to configure the swipe hint.
    @EnvironmentObject var state: StudioState
    // Controls the screen: false shows slides, true shows the melody recorder entry point.
    @State private var recording = false
    // The four lesson cards guiding the learner from mood-setting to capturing a tune.
    private let slides = [
        // First card encourages choosing an emotion to guide the melody's character.
        LessonSlide(title: "Start with a feeling", description: "Choose a mood: joyful, nostalgic, confident, calm, or something entirely your own. Let that emotion guide your notes."),
        // Second card suggests humming short phrases and repeating memorable ideas.
        LessonSlide(title: "Hum before you judge", description: "Play with short musical phrases. Repeat a memorable idea, then vary the ending to keep it interesting."),
        // Third card teaches note-length variety and the value of silence.
        LessonSlide(title: "Leave room to breathe", description: "Mix longer and shorter notes. Silence and repetition can be as powerful as complexity."),
        // Final card tells the learner when and how to record their idea.
        LessonSlide(title: "Capture the spark", description: "When a tune comes to mind, hum it and record it. Listen back and refine what you like.")
    ]
    // Switches between the slideshow and the recorder depending on lesson progress.
    var body: some View {
        // If the learner finished the slides, present the melody recording entry screen.
        if recording {
            // Pass the shared state into MelodyRecorderView so it can complete the module correctly.
            MelodyRecorderView().environmentObject(state)
        } else {
            // Otherwise show the slides with the module title, accent color, and optional swipe hint.
            LessonSlideshow(moduleTitle: "MELODY", accent: Palette.accent, slides: slides, showsSwipeHint: state.showModuleSpinHint) {
                // When the final swipe completes, flip the flag to replace slides with the recorder.
                recording = true
            }
        }
    }
}
