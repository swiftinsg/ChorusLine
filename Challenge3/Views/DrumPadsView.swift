// Import SwiftUI for the view hierarchy, grid layout, buttons, and environment access.
import SwiftUI

/// Plays the six built-in drum patterns.
// The beat machine screen: a grid of tappable pads that preview drum patterns through the audio engine.
struct DrumPadsView: View {
    // Read the shared app state to remember the selected beat and mark the module complete.
    @EnvironmentObject var state: StudioState
    // Access the presentation environment so the Done action can dismiss this screen.
    @Environment(\.dismiss) private var dismiss
    // Own a single audio engine for the screen's lifetime so beats can be started and stopped.
    @StateObject private var audio = MusicEngine()
    // Tracks which pad is currently selected, driving the highlight around the grid.
    @State private var selected = 0
    // Builds a scrollable screen with a title, instruction, pad grid, stop control, and Done button.
    var body: some View {
        // Let the content scroll if the grid and controls exceed the available height.
        ScrollView { VStack(spacing: 24) {
            // Show the screen's main heading.
            Text("BEAT MACHINE").font(.title.bold())
            // Tell the learner how to interact with the pads below.
            Text("Tap a pad to play its beat").foregroundStyle(Palette.muted)
            // Lay the beat pads out in a two-column adaptive grid with 15-point spacing.
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                // Create one button per drum pattern from the beats data.
                ForEach(beats) { beat in
                    // Handle a pad tap by selecting it, saving the choice, and starting its audio preview.
                    Button {
                        // Record the tapped pad's ID locally and in shared state for later recall.
                        selected = beat.id; state.selectedBeat = selected
                        // Stop any previously playing pattern, then play this beat's step sequence.
                        audio.stop(); audio.playBeat(beat.steps)
                    } label: {
                        // Stack the pad's icon, name, and description vertically.
                        VStack(spacing: 13) {
                            // A waveform glyph signals that this pad produces sound.
                            Image(systemName: "waveform").font(.largeTitle)
                            // Display the pattern's name, e.g. "Classic Pop".
                            Text(beat.name).font(.headline)
                            // Show a short description of the groove in a smaller, muted caption.
                            Text(beat.detail).font(.caption).foregroundStyle(Palette.cream.opacity(0.8))
                                // Allow the caption to wrap to multiple lines while keeping its height flexible.
                                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        // Make each pad fill its grid column and give it a comfortable minimum height.
                        }.frame(maxWidth: .infinity).frame(minHeight: 120, idealHeight: 125)
                            // Highlight the currently selected pad in the accent color; others use the panel color.
                            .background(selected == beat.id ? Palette.accent.opacity(0.45) : Palette.panel, in: RoundedRectangle(cornerRadius: 18))
                    // Remove default button styling so the custom rounded-rectangle pad design shows through.
                    }.buttonStyle(.plain)
                }
            }
            // Provide an explicit control to halt audio playback at any time.
            Button("■ Stop Sound") { audio.stop() }.buttonStyle(.bordered)
            // Push the Done button toward the bottom of the scrollable content.
            Spacer()
            // Finish the module, then dismiss after a short delay so completion feedback can be seen.
            PrimaryAction(title: "Done — Complete Module") { audio.stop(); state.finish(2); DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { dismiss() } }
        // Pad the whole stack so its contents don't touch the screen edges.
        }.padding() }.modifier(LessonBackground()).onDisappear { audio.stop() }
    }
}
