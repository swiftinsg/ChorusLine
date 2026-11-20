import SwiftUI

/// Combines a chord progression and drum beat into a saved song idea.
struct SandboxView: View {
    @EnvironmentObject var state: StudioState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audio = MusicEngine()
    @State private var songName = "My First Song"
    @State private var chosenProgression = 0
    @State private var chosenBeat = 0
    @State private var saved = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("GOLDEN SANDBOX").font(.title.bold()).foregroundStyle(Palette.gold)
                Text("Build your first musical idea with chords and rhythm.").foregroundStyle(.gray)
                TextField("Song title", text: $songName).textFieldStyle(.roundedBorder).foregroundStyle(.black)
                Text("1. CHOOSE YOUR CHORDS").font(.headline)
                Picker("Chord Progression", selection: $chosenProgression) {
                    ForEach(progressions) { Text("\( $0.name ): \($0.chords.joined(separator: "–"))").tag($0.id) }
                }.tint(Palette.gold)
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { i in
                        Button(progressions[chosenProgression].chords[i]) {
                            audio.playChord(progressions[chosenProgression].notes[i])
                        }.frame(maxWidth: .infinity).padding(.vertical, 18)
                            .background(.white, in: RoundedRectangle(cornerRadius: 10)).foregroundStyle(.black)
                    }
                }
                Button("▶ Play Chord Loop") {
                    audio.stop()
                    for chord in progressions[chosenProgression].notes { audio.playChord(chord, duration: 0.65) }
                }.buttonStyle(.bordered)
                Divider()
                Text("2. CHOOSE YOUR DRUM BEAT").font(.headline)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(beats) { beat in
                        Button(beat.name) {
                            chosenBeat = beat.id
                            audio.stop(); audio.playBeat(beat.steps)
                        }.frame(maxWidth: .infinity).padding(15)
                            .background(chosenBeat == beat.id ? Palette.gold.opacity(0.45) : Palette.panel, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                Button("▶ Play Beat") { audio.stop(); audio.playBeat(beats[chosenBeat].steps) }.buttonStyle(.bordered)
                Button("■ Stop") { audio.stop() }.buttonStyle(.bordered)
                Divider()
                Text("3. SAVE YOUR SONG IDEA").font(.headline)
                Text("Your chord progression and drum choice will be saved on this device. You can add your recorded melody from Module 4 separately.")
                    .font(.subheadline).foregroundStyle(.gray)
                PrimaryAction(title: "Save Song Idea") {
                    let idea = SongIdea(title: songName, progression: chosenProgression, beat: chosenBeat, createdAt: Date())
                    SongLibrary.save(idea)
                    state.finish(4)
                    saved = true
                }
                if saved {
                    Label("Saved to your song library!", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    PrimaryAction(title: "▶ Play Your Song") {
                        audio.playSong(progression: progressions[chosenProgression], beat: beats[chosenBeat])
                    }
                }
                NavigationLink("View Saved Songs", destination: SongLibraryView())
                    .frame(maxWidth: .infinity).padding(15).background(Palette.panel, in: RoundedRectangle(cornerRadius: 14))
            }.padding()
        }.modifier(LessonBackground()).navigationTitle("Sandbox")
            .onAppear { chosenProgression = state.selectedProgression; chosenBeat = state.selectedBeat }
            .onDisappear { audio.stop() }
    }
}
