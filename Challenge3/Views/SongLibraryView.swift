import SwiftUI

/// Lists, previews and deletes saved song ideas.
struct SongLibraryView: View {
    @StateObject private var audio = MusicEngine()
    @State private var songs = SongLibrary.load()
    var body: some View {
        List {
            if songs.isEmpty { Text("No song ideas saved yet.") }
            ForEach(songs) { song in
                VStack(alignment: .leading, spacing: 6) {
                    Text(song.title).font(.headline)
                    Text("\(progressions[song.progression].chords.joined(separator: " – ")) · \(beats[song.beat].name) beat")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(song.createdAt, style: .date).font(.caption2).foregroundStyle(.secondary)
                    Button("▶ Play song") {
                        guard progressions.indices.contains(song.progression), beats.indices.contains(song.beat) else { return }
                        audio.playSong(progression: progressions[song.progression], beat: beats[song.beat])
                    }.buttonStyle(.bordered)
                }
            }
            .onDelete { offsets in
                songs.remove(atOffsets: offsets)
                if let data = try? JSONEncoder().encode(songs) { UserDefaults.standard.set(data, forKey: SongLibrary.key) }
            }
        }.navigationTitle("My Songs").onDisappear { audio.stop() }
    }
}
