import Foundation

/// A saved combination of song title, chord progression and drum beat.
struct SongIdea: Codable, Identifiable {
    var id = UUID()
    let title: String
    let progression: Int
    let beat: Int
    let createdAt: Date
}

/// Persists song ideas in `UserDefaults`.
enum SongLibrary {
    static let key = "vinylStudioSongs"
    static func load() -> [SongIdea] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([SongIdea].self, from: data)) ?? []
    }
    static func save(_ song: SongIdea) {
        var songs = load(); songs.insert(song, at: 0)
        if let data = try? JSONEncoder().encode(songs) { UserDefaults.standard.set(data, forKey: key) }
    }
}
