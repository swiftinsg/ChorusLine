// Import SwiftUI for the View protocol, state wrappers, and environment object support.
import SwiftUI

/// Module 1: walks through the sections of a song before the quiz.
// Module 1's flow: teach song sections with slides, then launch the structure quiz.
struct StructureView: View {
    // Read the shared app state so it can be passed to the quiz and to configure the swipe hint.
    @EnvironmentObject var state: StudioState
    // Controls the screen: false shows slides, true shows the quiz.
    @State private var quiz = false
    // The seven lesson cards, one per typical section of a song in order from start to finish.
    private let slides = [
        // Intro: explains how the opening establishes mood and sometimes the main hook.
        LessonSlide(title: "INTRO", description: "The opening sets the mood and draws listeners into the song. Some intros introduce the main hook."),
        // Verse 1: describes introducing the story with a restrained melody.
        LessonSlide(title: "VERSE 1", description: "The first verse introduces the story, setting, or emotion. It usually has a more restrained melody than the chorus."),
        // Pre-chorus: explains its role in building tension toward the chorus.
        LessonSlide(title: "PRE-CHORUS", description: "A short build-up that increases tension and leads naturally into the chorus."),
        // Chorus: highlights the repeated hook and central message of the song.
        LessonSlide(title: "CHORUS", description: "The central repeated section, often containing the strongest hook and the song's main message."),
        // Verse 2: shows how a second verse develops the story over a familiar pattern.
        LessonSlide(title: "VERSE 2", description: "Develops the story with new details while keeping a familiar musical pattern."),
        // Bridge: explains the contrasting section that adds variety before the final chorus.
        LessonSlide(title: "BRIDGE", description: "A contrasting section that adds variety or a fresh perspective before the final chorus."),
        // Outro: describes how the ending gives closure, possibly by repeating a hook or fading out.
        LessonSlide(title: "OUTRO", description: "The ending provides a sense of closure, perhaps repeating a hook or fading out.")
    ]
    // Switches between the slideshow and the quiz depending on lesson progress.
    var body: some View {
        // If the learner finished the slides, present the structure quiz.
        if quiz {
            // Pass the shared state into StructureQuiz so answers and progress are tracked.
            StructureQuiz().environmentObject(state)
        } else {
            // Otherwise show the slides with the module title, accent color, and optional swipe hint.
            LessonSlideshow(moduleTitle: "SONG STRUCTURE", accent: Palette.accent, slides: slides, showsSwipeHint: state.showModuleSpinHint) {
                // When the final swipe completes, flip the flag to replace slides with the quiz.
                quiz = true
            }
        }
    }
}
