import SwiftUI

/// Module 4: melody tips, followed by the melody drawing experience.
/// Flow: lesson slideshow -> `MelodyRecorderView` (entry screen) -> `MelodyDrawView` canvas.
struct MelodyView: View {
    @EnvironmentObject var state: StudioState
    @State private var recording = false
    private let slides = [
        LessonSlide(title: "Start with a feeling", description: "Choose a mood: joyful, nostalgic, confident, calm, or something entirely your own. Let that emotion guide your notes."),
        LessonSlide(title: "Hum before you judge", description: "Play with short musical phrases. Repeat a memorable idea, then vary the ending to keep it interesting."),
        LessonSlide(title: "Leave room to breathe", description: "Mix longer and shorter notes. Silence and repetition can be as powerful as complexity."),
        LessonSlide(title: "Capture the spark", description: "When a tune comes to mind, hum it and record it. Listen back and refine what you like.")
    ]
    var body: some View {
        if recording {
            MelodyRecorderView().environmentObject(state)
        } else {
            LessonSlideshow(moduleTitle: "MELODY", accent: Palette.accent, slides: slides, showsSwipeHint: state.showModuleSpinHint) {
                recording = true
            }
        }
    }
}
