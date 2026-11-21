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
    @State private var selectedKey = 0
    @State private var chosenBeat = 0
    @State private var lastKey = "C"
    @State private var transposeOffset = 0
    @State private var bpm: Double = 100
    @State private var saved = false
    private static let keyNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    // Pitch classes (0=C ... 11=B) that belong to a natural major scale.
    private static let majorScale: Set<Int> = [0, 2, 4, 5, 7, 9, 11]

    /// Progressions whose chords are all diatonic to the selected song key (major scale).
    /// Filtering is based on MIDI note pitch classes in the progression data.
    private var filteredProgressions: [Progression] {
        progressions.filter { progression in
            progression.notes.allSatisfy { chord in
                chord.allSatisfy { midi in
                    Self.majorScale.contains(((midi - selectedKey) % 12 + 12) % 12)
                }
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("GOLDEN SANDBOX").font(.title.bold()).foregroundStyle(Palette.gold)
                Text("Build your first musical idea with chords and rhythm.").foregroundStyle(Palette.muted)
                TextField("Song title", text: $songName).textFieldStyle(.roundedBorder)

                Text("1. CHOOSE YOUR CHORDS").font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    keyMenu
                    progressionMenu
                }

                if let selected = progressions.first(where: { $0.id == chosenProgression }) {
                    VStack(spacing: 3) {
                        Text(selected.name)
                            .font(.headline).foregroundStyle(Palette.accent)
                        Text(selected.mood)
                            .font(.caption).foregroundStyle(Palette.muted)
                    }
                    .frame(maxWidth: .infinity)
                }

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
                            audio.stop()
                            // Preview with reduced drum gain so beats sit closer to melody/chord levels.
                            audio.playBeat(beat.steps, gain: 0.35)
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
                    // Save the user's actual current chord notes/tempo/beat so playback matches what they heard.
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
                        // Use reduced drum gain in the combined preview for better balance.
                        audio.playSong(progression: customProgression(), beat: beats[chosenBeat], bpm: bpm, drumGain: 0.35)
                    }
                }
                NavigationLink("View Saved Songs", destination: SongLibraryView())
                    .frame(maxWidth: .infinity).padding(15).background(Palette.panel, in: RoundedRectangle(cornerRadius: 14))
            }.padding()
        }.modifier(LessonBackground()).navigationTitle("Sandbox")
            .onAppear {
                selectedKey = 0
                lastKey = Self.keyNames[selectedKey]
                transposeOffset = 0
                chosenProgression = state.selectedProgression
                chosenBeat = state.selectedBeat
                if !filteredProgressions.contains(where: { $0.id == chosenProgression }) {
                    if let first = filteredProgressions.first {
                        chosenProgression = first.id
                        state.selectedProgression = chosenProgression
                    }
                }
            }
            .onChange(of: chosenProgression) { _, _ in saved = false }
            .onChange(of: chosenBeat) { _, _ in saved = false }
            .onChange(of: transposeOffset) { _, _ in saved = false }
            .onChange(of: bpm) { _, _ in saved = false }
            .onDisappear { audio.stop() }
    }

    /// Shows each chord in the progression as a tappable column of its notes.
    private var chordColumnsView: some View {
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
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Play chord \(chordLabel(for: notes))")
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Lets the user choose the song key and filters available progressions.
    private var keyMenu: some View {
        Menu {
            ForEach(0..<Self.keyNames.count, id: \.self) { index in
                Button {
                    selectKey(index)
                } label: {
                    if selectedKey == index {
                        Label(Self.keyNames[index], systemImage: "checkmark")
                    } else {
                        Text(Self.keyNames[index])
                    }
                }
            }
        } label: {
            Label("Key: \(Self.keyNames[selectedKey])", systemImage: "music.note")
                .font(.subheadline.bold())
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Palette.panel, in: Capsule())
                .overlay(Capsule().stroke(Palette.accent.opacity(0.35)))
        }
        .tint(Palette.cream)
    }

    /// Lists progressions available in the selected key.
    private var progressionMenu: some View {
        Menu {
            ForEach(filteredProgressions) { progression in
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

    /// Updates the selected song key and keeps the chosen progression valid.
    private func selectKey(_ index: Int) {
        selectedKey = index
        lastKey = Self.keyNames[index]
        transposeOffset = 0
        saved = false
        if !filteredProgressions.contains(where: { $0.id == chosenProgression }) {
            if let first = filteredProgressions.first {
                chosenProgression = first.id
                state.selectedProgression = chosenProgression
            }
        }
    }

    /// Transposes the chosen progression so it is rooted on `root`, and sets it as the song's key.
    private func transpose(to root: Int) {
        selectedKey = ((root - 60) % 12 + 12) % 12
        lastKey = Self.keyNames[selectedKey]
        transposeOffset = 0
        saved = false
        if !filteredProgressions.contains(where: { $0.id == chosenProgression }) {
            if let first = filteredProgressions.first {
                chosenProgression = first.id
                state.selectedProgression = chosenProgression
            }
        }
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    /// The currently selected progression transposed to the chosen key.
    private func currentChordNotes() -> [[Int]] {
        guard let progression = progressions.first(where: { $0.id == chosenProgression }) else { return [] }
        return progression.notes.map { notes in notes.map { $0 + transposeOffset } }
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
