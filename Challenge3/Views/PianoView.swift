import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Lets the learner play any chord progression in any key on a piano.
struct PianoView: View {
    @EnvironmentObject var state: StudioState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audio = MusicEngine()
    @State private var chosen = 0
    @State private var selectedKey = 0
    @State private var lastKey = "C"
    @State private var transposeOffset = 0
    @State private var bpm: Double = 100
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
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CHORD PIANO").font(.title.bold())
                    Text("Choose a key and progression, tap a chord column to hear it, or press a piano key to transpose the progression.")
                        .font(.caption).foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 8) {
                    keyMenu
                    progressionMenu
                }
            }

            if let selected = progressions.first(where: { $0.id == chosen }) {
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
                Text("Tap a key to transpose")
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

            Spacer(minLength: 0)

            PrimaryAction(title: "Done — Complete Module") {
                audio.stop()
                state.finish(1)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { dismiss() }
            }
        }
        .padding(20)
        }
        .modifier(LessonBackground())
        .navigationTitle("")
        .onAppear {
            selectedKey = 0
            lastKey = Self.keyNames[selectedKey]
            transposeOffset = 0
            chosen = state.selectedProgression
            if !filteredProgressions.contains(where: { $0.id == chosen }) {
                if let first = filteredProgressions.first {
                    chosen = first.id
                    state.selectedProgression = chosen
                }
            }
        }
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
                    chosen = progression.id
                    state.selectedProgression = chosen
                } label: {
                    if chosen == progression.id {
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
    /// In this view, selecting a key uses progressions in that key directly (no extra transpose offset).
    private func selectKey(_ index: Int) {
        selectedKey = index
        lastKey = Self.keyNames[index]
        transposeOffset = 0
        if !filteredProgressions.contains(where: { $0.id == chosen }) {
            if let first = filteredProgressions.first {
                chosen = first.id
                state.selectedProgression = chosen
            }
        }
    }

    /// Sets the song key from a tapped piano note (C4..B4) and keeps the progression list valid.
    /// This changes key/filtering without auto-playing the progression.
    private func transpose(to root: Int) {
        selectedKey = ((root - 60) % 12 + 12) % 12
        lastKey = Self.keyNames[selectedKey]
        transposeOffset = 0
        if !filteredProgressions.contains(where: { $0.id == chosen }) {
            if let first = filteredProgressions.first {
                chosen = first.id
                state.selectedProgression = chosen
            }
        }
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    /// The currently selected progression transposed to the chosen key.
    private func currentChordNotes() -> [[Int]] {
        guard let progression = progressions.first(where: { $0.id == chosen }) else { return [] }
        return progression.notes.map { notes in notes.map { $0 + transposeOffset } }
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
