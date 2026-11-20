import SwiftUI
import UIKit

/// Lets the learner play any chord progression in any key on a piano.
struct PianoView: View {
    @EnvironmentObject var state: StudioState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audio = MusicEngine()
    @State private var chosen = 0
    @State private var lastKey = "C"
    @State private var transposeOffset = 0
    @State private var bpm: Double = 100
    private static let keyNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CHORD PIANO").font(.title.bold())
                    Text("Pick a progression, set a tempo, then press a key to hear it in that key.")
                        .font(.caption).foregroundStyle(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                progressionMenu
            }

            VStack(spacing: 3) {
                Text(progressions[chosen].name)
                    .font(.headline).foregroundStyle(Palette.accent)
                Text(transposedChordLabels())
                    .font(.subheadline)
                Text(progressions[chosen].mood)
                    .font(.caption).foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity)

            PianoKeyboard { midi in play(root: midi) }
                .frame(height: 200)

            HStack {
                Text("Playing in \(lastKey)")
                    .font(.caption.bold()).foregroundStyle(Palette.accent)
                Spacer()
                Text("Tap a key to transpose")
                    .font(.caption).foregroundStyle(.gray)
            }

            HStack(spacing: 12) {
                Label("Tempo", systemImage: "metronome")
                    .font(.caption.bold())
                    .foregroundStyle(.gray)
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
        .modifier(LessonBackground())
        .navigationTitle("")
        .onAppear { chosen = state.selectedProgression }
        .onDisappear { audio.stop() }
    }

    /// Lists every available progression in a compact top-right menu.
    private var progressionMenu: some View {
        Menu {
            ForEach(progressions) { progression in
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

    /// Plays the chosen progression transposed so it is rooted on `root`.
    private func play(root: Int) {
        audio.stop()
        transposeOffset = root - 60
        audio.playProgression(progressions[chosen].notes.map { notes in notes.map { $0 + transposeOffset } }, bpm: bpm)
        lastKey = Self.keyNames[((root - 60) % 12 + 12) % 12]
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// Chord labels for the selected progression, transposed to the last pressed key.
    private func transposedChordLabels() -> String {
        progressions[chosen].notes
            .map { chordLabel(for: $0.map { $0 + transposeOffset }) }
            .joined(separator: "  –  ")
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
}
