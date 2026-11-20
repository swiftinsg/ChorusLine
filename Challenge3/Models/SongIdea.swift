import Foundation

/// A saved combination of song title, chord progression and drum beat.
struct SongIdea: Codable, Identifiable {
    var id = UUID()
    let title: String
    /// Legacy preset progression index. Used when `chordNotes` is not available.
    let progression: Int?
    /// The chord progression notes (one chord per bar), as entered in the sandbox.
    let chordNotes: [[Int]]?
    /// Playback tempo in beats per minute.
    let bpm: Double?
    let beat: Int
    let createdAt: Date

    init(id: UUID = UUID(), title: String, progression: Int? = nil, chordNotes: [[Int]]? = nil, bpm: Double? = nil, beat: Int, createdAt: Date) {
        self.id = id
        self.title = title
        self.progression = progression
        self.chordNotes = chordNotes
        self.bpm = bpm
        self.beat = beat
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, progression, chordNotes, bpm, beat, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        title = (try? container.decode(String.self, forKey: .title)) ?? "Untitled"
        progression = try? container.decode(Int.self, forKey: .progression)
        chordNotes = try? container.decode([[Int]].self, forKey: .chordNotes)
        bpm = try? container.decode(Double.self, forKey: .bpm)
        beat = (try? container.decode(Int.self, forKey: .beat)) ?? 0
        createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
    }
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
