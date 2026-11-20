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
    @State private var lastKey = "C"
    @State private var transposeOffset = 0
    @State private var bpm: Double = 100
    private static let keyNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]

    var body: some View {
        ScrollView {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CHORD PIANO").font(.title.bold())
                    Text("Pick a progression, tap a chord column to hear it, or press a piano key to transpose the progression.")
                        .font(.caption).foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                progressionMenu
            }

            VStack(spacing: 3) {
                Text(progressions[chosen].name)
                    .font(.headline).foregroundStyle(Palette.accent)
                Text(progressions[chosen].mood)
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
        .onAppear { chosen = state.selectedProgression }
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

    /// Transposes the chosen progression so it is rooted on `root` without playing it.
    private func transpose(to root: Int) {
        transposeOffset = root - 60
        lastKey = Self.keyNames[((root - 60) % 12 + 12) % 12]
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    /// The currently selected progression transposed to the chosen key.
    private func currentChordNotes() -> [[Int]] {
        progressions[chosen].notes.map { notes in notes.map { $0 + transposeOffset } }
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
