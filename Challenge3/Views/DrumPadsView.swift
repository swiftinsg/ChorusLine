import SwiftUI

/// Plays the six built-in drum patterns.
struct DrumPadsView: View {
    @EnvironmentObject var state: StudioState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audio = MusicEngine()
    @State private var selected = 0
    var body: some View {
        ScrollView { VStack(spacing: 24) {
            Text("BEAT MACHINE").font(.title.bold())
            Text("Tap a pad to play its beat").foregroundStyle(Palette.muted)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(beats) { beat in
                    Button {
                        selected = beat.id; state.selectedBeat = selected
                        audio.stop(); audio.playBeat(beat.steps)
                    } label: {
                        VStack(spacing: 13) {
                            Image(systemName: "waveform").font(.largeTitle)
                            Text(beat.name).font(.headline)
                            Text(beat.detail).font(.caption).foregroundStyle(Palette.cream.opacity(0.8))
                                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        }.frame(maxWidth: .infinity).frame(minHeight: 120, idealHeight: 125)
                            .background(selected == beat.id ? Palette.accent.opacity(0.45) : Palette.panel, in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain)
                }
            }
            Button("■ Stop Sound") { audio.stop() }.buttonStyle(.bordered)
            Spacer()
            PrimaryAction(title: "Done — Complete Module") { audio.stop(); state.finish(2); DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { dismiss() } }
        }.padding() }.modifier(LessonBackground()).onDisappear { audio.stop() }
    }
}
