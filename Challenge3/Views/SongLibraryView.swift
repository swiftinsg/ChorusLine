import SwiftUI

/// Lists, previews and deletes saved song ideas.
struct SongLibraryView: View {
    @StateObject private var audio = MusicEngine()
    @State private var songs = SongLibrary.load()
    var body: some View {
        List {
            if songs.isEmpty {
                Text("No song ideas saved yet.")
                    .foregroundStyle(Palette.muted)
                    .listRowBackground(Palette.panel)
            }
            ForEach(songs) { song in
                VStack(alignment: .leading, spacing: 6) {
                    Text(song.title).font(.headline)
                    Text("\(chordSummary(for: song)) · \(beats[safe: song.beat]?.name ?? "Unknown") beat")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(song.createdAt, style: .date).font(.caption2).foregroundStyle(.secondary)
                    Button("▶ Play song") {
                        play(song)
                    }.buttonStyle(.bordered)
                }
                .listRowBackground(Palette.panel)
            }
            .onDelete { offsets in
                songs.remove(atOffsets: offsets)
                if let data = try? JSONEncoder().encode(songs) { UserDefaults.standard.set(data, forKey: SongLibrary.key) }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.background.ignoresSafeArea())
        .foregroundStyle(Palette.cream)
        .tint(Palette.accent)
        .navigationTitle("My Songs").onDisappear { audio.stop() }
    }

    /// Plays a saved idea using custom chord notes when available; falls back to legacy preset progression IDs.
    private func play(_ song: SongIdea) {
        guard let beat = beats[safe: song.beat] else { return }
        if let notes = song.chordNotes, !notes.isEmpty {
            let progression = Progression(id: -1, name: song.title, mood: "Custom", chords: notes.map(chordLabel(for:)), notes: notes)
            audio.playSong(progression: progression, beat: beat, bpm: song.bpm ?? 108)
        } else if let index = song.progression, let progression = progressions[safe: index] {
            audio.playSong(progression: progression, beat: beat, bpm: song.bpm ?? 108)
        }
    }

    private func chordSummary(for song: SongIdea) -> String {
        if let notes = song.chordNotes, !notes.isEmpty {
            return notes.map(chordLabel(for:)).joined(separator: " – ")
        }
        if let index = song.progression, let progression = progressions[safe: index] {
            return progression.chords.joined(separator: " – ")
        }
        return "Unknown chords"
    }

    private func chordLabel(for midiNotes: [Int]) -> String {
        let keyNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        let ordered = midiNotes.sorted()
        guard let root = ordered.first else { return "" }
        let rootName = keyNames[((root % 12) + 12) % 12]
        let intervals = Set(ordered.map { $0 - root })
        let quality = intervals.contains(3) ? "m" : ""
        return rootName + quality
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
