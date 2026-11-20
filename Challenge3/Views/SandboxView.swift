import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Combines a chord progression and drum beat into a saved song idea.
struct SandboxView: View {
    @EnvironmentObject var state: StudioState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audio = MusicEngine()
    @State private var songName = "My First Song"
    @State private var chosenProgression = 0
    @State private var chosenBeat = 0
    @State private var lastKey = "C"
    @State private var transposeOffset = 0
    @State private var bpm: Double = 100
    @State private var saved = false
    private static let keyNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("GOLDEN SANDBOX").font(.title.bold()).foregroundStyle(Palette.gold)
                Text("Build your first musical idea with chords and rhythm.").foregroundStyle(Palette.muted)
                TextField("Song title", text: $songName).textFieldStyle(.roundedBorder)

                Text("1. CHOOSE YOUR CHORDS").font(.headline)
                progressionMenu

                VStack(spacing: 3) {
                    Text(progressions[chosenProgression].name)
                        .font(.headline).foregroundStyle(Palette.accent)
                    Text(progressions[chosenProgression].mood)
                        .font(.caption).foregroundStyle(Palette.muted)
                }
                .frame(maxWidth: .infinity)

                chordColumnsView

                PianoKeyboard { midi in transpose(to: midi) }
                    .frame(minHeight: 140, idealHeight: 180, maxHeight: 220)

                HStack {
                    Text("Playing in \(lastKey)")
                        .font(.caption.bold()).foregroundStyle(Palette.accent)
                    Spacer()
                    Text("Tap a key to set your song's key")
                        .font(.caption).foregroundStyle(Palette.muted)
                }

                HStack(spacing: 12) {
                    Label("Tempo", systemImage: "metronome")
                        .font(.caption.bold())
                        .foregroundStyle(Palette.muted)
                    Slider(value: $bpm, in: 60...180, step: 5)
                        .tint(Palette.accent)
                        .accessibilityLabel("Tempo")
                        .accessibilityValue("\(Int(bpm)) beats per minute")
                    Text("\(Int(bpm)) BPM")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(Palette.accent)
                        .frame(width: 64, alignment: .trailing)
                }

                Divider()
                Text("2. CHOOSE YOUR DRUM BEAT").font(.headline)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                    ForEach(beats) { beat in
                        Button(beat.name) {
                            chosenBeat = beat.id
                            audio.stop(); audio.playBeat(beat.steps)
                        }.frame(maxWidth: .infinity).padding(15)
                            .background(chosenBeat == beat.id ? Palette.gold.opacity(0.45) : Palette.panel, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                Button("■ Stop") { audio.stop() }.buttonStyle(.bordered)
                Divider()
                Text("3. SAVE YOUR SONG IDEA").font(.headline)
                Text("Your current chord progression, key, tempo and drum choice will be saved in this song idea. You can add your recorded melody from Module 4 separately.")
                    .font(.subheadline).foregroundStyle(Palette.muted)
                PrimaryAction(title: "Save Song Idea", tint: Palette.gold) {
                    let idea = SongIdea(
                        title: songName,
                        progression: chosenProgression,
                        chordNotes: currentChordNotes(),
                        bpm: bpm,
                        beat: chosenBeat,
                        createdAt: Date()
                    )
                    SongLibrary.save(idea)
                    state.finish(4, animate: false)
                    saved = true
                }
                if saved {
                    Label("Saved to your song library!", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    PrimaryAction(title: "▶ Play Your Song", tint: Palette.gold) {
                        audio.playSong(progression: customProgression(), beat: beats[chosenBeat], bpm: bpm)
                    }
                }
                NavigationLink("View Saved Songs", destination: SongLibraryView())
                    .frame(maxWidth: .infinity).padding(15).background(Palette.panel, in: RoundedRectangle(cornerRadius: 14))
            }.padding()
        }.modifier(LessonBackground()).navigationTitle("Sandbox")
            .onAppear { chosenProgression = state.selectedProgression; chosenBeat = state.selectedBeat }
            .onChange(of: chosenProgression) { _, _ in saved = false }
            .onChange(of: chosenBeat) { _, _ in saved = false }
            .onChange(of: transposeOffset) { _, _ in saved = false }
            .onChange(of: bpm) { _, _ in saved = false }
            .onDisappear { audio.stop() }
    }

    /// Shows each chord in the progression as a tappable column of its notes.
    private var chordColumnsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: 8) {
            ForEach(Array(currentChordNotes().enumerated()), id: \.offset) { index, notes in
                Button {
                    audio.stop()
                    audio.playChord(notes)
                    #if os(iOS)
                    UISelectionFeedbackGenerator().selectionChanged()
                    #endif
                } label: {
                    VStack(spacing: 6) {
                        Text(chordLabel(for: notes))
                            .font(.headline.bold())
                            .foregroundStyle(Palette.cream)
                        Text("Chord \(index + 1)")
                            .font(.caption2)
                            .foregroundStyle(Palette.muted)
                        VStack(spacing: 4) {
                            ForEach(Array(notes.enumerated()), id: \.offset) { _, midi in
                                Text(noteName(for: midi))
                                    .font(.caption.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 5)
                                    .background(Palette.accent.opacity(0.22), in: RoundedRectangle(cornerRadius: 6))
                                    .foregroundStyle(Palette.cream)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 6)
                    .background(Palette.panel, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.accent.opacity(0.35), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Play chord \(chordLabel(for: notes))")
            }
        }
        }
    }

    /// Lists every available progression, matching the chord progression module menu.
    private var progressionMenu: some View {
        Menu {
            ForEach(progressions) { progression in
                Button {
                    chosenProgression = progression.id
                    state.selectedProgression = chosenProgression
                    saved = false
                } label: {
                    if chosenProgression == progression.id {
                        Label("\(progression.name) · \(progression.chords.joined(separator: "–"))", systemImage: "checkmark")
                    } else {
                        Text("\(progression.name) · \(progression.chords.joined(separator: "–"))")
                    }
                }
            }
        } label: {
            Label("Progressions", systemImage: "music.note.list")
                .font(.subheadline.bold())
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Palette.panel, in: Capsule())
                .overlay(Capsule().stroke(Palette.accent.opacity(0.35)))
        }
        .tint(Palette.cream)
    }

    /// Transposes the chosen progression so it is rooted on `root`, and sets it as the song's key.
    private func transpose(to root: Int) {
        transposeOffset = root - 60
        lastKey = Self.keyNames[((root - 60) % 12 + 12) % 12]
        saved = false
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    /// The currently selected progression transposed to the chosen key.
    private func currentChordNotes() -> [[Int]] {
        progressions[chosenProgression].notes.map { notes in notes.map { $0 + transposeOffset } }
    }

    /// Builds a custom progression for playback using the user's current chord selection.
    private func customProgression() -> Progression {
        let notes = currentChordNotes()
        return Progression(
            id: -1,
            name: songName,
            mood: "Custom",
            chords: notes.map(chordLabel(for:)),
            notes: notes
        )
    }

    /// Names a chord from its MIDI notes (e.g. major "C", minor "Am").
    private func chordLabel(for midiNotes: [Int]) -> String {
        let ordered = midiNotes.sorted()
        guard let root = ordered.first else { return "" }
        let rootName = Self.keyNames[((root % 12) + 12) % 12]
        let intervals = Set(ordered.map { $0 - root })
        let quality = intervals.contains(3) ? "m" : ""
        return rootName + quality
    }

    /// Returns the note name for a MIDI note number.
    private func noteName(for midi: Int) -> String {
        Self.keyNames[((midi % 12) + 12) % 12]
    }
}
