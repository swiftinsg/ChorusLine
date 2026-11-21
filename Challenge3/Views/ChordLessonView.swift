import SwiftUI

/// Module 2: introduces chords and progressions, then opens the piano.
/// Flow: lesson slideshow -> interactive `PianoView`.
struct ChordLessonView: View {
    @EnvironmentObject var state: StudioState
    @State private var showPiano = false
    private let slides = [
        LessonSlide(title: "What is a chord?", description: "A chord is a group of notes played together. Different combinations create different feelings."),
        LessonSlide(title: "What is a progression?", description: "A chord progression is a sequence of chords repeated through part of a song. Try C–G–Am–F, a common pop progression."),
        LessonSlide(title: "How to use the piano", description: "Choose a progression, then tap its chord buttons to hear them. Use Play All to hear the full sequence.")
    ]
    var body: some View {
        if showPiano {
            PianoView().environmentObject(state)
        } else {
            LessonSlideshow(moduleTitle: "CHORD PROGRESSION", accent: Palette.accent, slides: slides, showsSwipeHint: state.showModuleSpinHint) {
                showPiano = true
            }
        }
    }
}
