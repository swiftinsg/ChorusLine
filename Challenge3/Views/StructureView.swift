import SwiftUI

/// Module 1: walks through the sections of a song before the quiz.
struct StructureView: View {
    @EnvironmentObject var state: StudioState
    @State private var quiz = false
    private let slides = [
        LessonSlide(title: "INTRO", description: "The opening sets the mood and draws listeners into the song. Some intros introduce the main hook."),
        LessonSlide(title: "VERSE 1", description: "The first verse introduces the story, setting, or emotion. It usually has a more restrained melody than the chorus."),
        LessonSlide(title: "PRE-CHORUS", description: "A short build-up that increases tension and leads naturally into the chorus."),
        LessonSlide(title: "CHORUS", description: "The central repeated section, often containing the strongest hook and the song's main message."),
        LessonSlide(title: "VERSE 2", description: "Develops the story with new details while keeping a familiar musical pattern."),
        LessonSlide(title: "BRIDGE", description: "A contrasting section that adds variety or a fresh perspective before the final chorus."),
        LessonSlide(title: "OUTRO", description: "The ending provides a sense of closure, perhaps repeating a hook or fading out.")
    ]
    var body: some View {
        if quiz {
            StructureQuiz().environmentObject(state)
        } else {
            LessonSlideshow(moduleTitle: "SONG STRUCTURE", accent: .purple, slides: slides, showsSwipeHint: true) {
                quiz = true
            }
        }
    }
}
