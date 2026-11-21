import SwiftUI

/// Module 3: introduces rhythm, then opens the drum pads.
/// Flow: lesson slideshow -> interactive `DrumPadsView`.
struct DrumLessonView: View {
    @EnvironmentObject var state: StudioState
    @State private var showPads = false
    private let slides = [
        LessonSlide(title: "Rhythm is the heartbeat", description: "A drum beat sets the pulse and energy of a song. Kick drums create the low thump, snares add a sharp backbeat, and hi-hats mark smaller subdivisions."),
        LessonSlide(title: "Explore pop grooves", description: "Classic pop, dance pop, synth pop, pop rock, pop ballad and R&B pop use different patterns. Tap each pad to hear its rhythm and discover what fits your song.")
    ]
    var body: some View {
        if showPads {
            DrumPadsView().environmentObject(state)
        } else {
            LessonSlideshow(moduleTitle: "DRUM BEATS", accent: Palette.accent, slides: slides, showsSwipeHint: state.showModuleSpinHint) {
                showPads = true
            }
        }
    }
}
