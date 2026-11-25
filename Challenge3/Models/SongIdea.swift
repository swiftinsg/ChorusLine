// -----------------------------------------------------------------------------
// FILE SUMMARY — Models/SongIdea.swift
// -----------------------------------------------------------------------------
// PURPOSE: Saved song idea model plus UserDefaults-backed persistence helpers.
//
// HOW IT WORKS:
//   • SongIdea — Codable/Identifiable value holding a title, optional legacy
//     progression index, optional custom MIDI `chordNotes`, optional `bpm`, a
//     beat index and a creation date. Its memberwise init defaults optional data.
//   • CodingKeys — maps Swift properties to the keys stored in JSON.
//   • init(from:) — tolerant decoder that substitutes safe defaults (new UUID,
//     "Untitled", 0, now) so older saved songs still load.
//   • SongLibrary.load() — decodes the JSON array at key `vinylStudioSongs`,
//     returning an empty array when missing or corrupt.
//   • SongLibrary.save(_:) — prepends a new idea to the loaded array and writes
//     the encoded JSON back to UserDefaults.
// -----------------------------------------------------------------------------

// Import Foundation for Codable, UUID, Date, and UserDefaults persistence types.
import Foundation

/// A saved combination of song title, chord progression and drum beat.
// Codable lets the struct be archived as JSON; Identifiable supports SwiftUI lists.
struct SongIdea: Codable, Identifiable {
    // A fresh UUID gives each saved idea a stable identity across app launches.
    var id = UUID()
    // The title the user typed for this song idea.
    let title: String
    /// Legacy preset progression index. Used when `chordNotes` is not available.
    // Optional because songs saved by older versions may only have this index.
    let progression: Int?
    /// The chord progression notes (one chord per bar), as entered in the sandbox.
    // Optional so older saved songs without custom notes can still be decoded.
    let chordNotes: [[Int]]?
    /// Playback tempo in beats per minute.
    // Optional so missing tempo data can fall back to a default during playback.
    let bpm: Double?
    // Index into the shared drum-beat presets, with 0 as the fallback.
    let beat: Int
    // Timestamp recording when the idea was saved, useful for ordering history.
    let createdAt: Date

    // Memberwise initializer with defaults so callers may omit optional or legacy fields.
    init(id: UUID = UUID(), title: String, progression: Int? = nil, chordNotes: [[Int]]? = nil, bpm: Double? = nil, beat: Int, createdAt: Date) {
        // Store the provided identity, generating a new UUID when none is passed.
        self.id = id
        // Store the user-facing title.
        self.title = title
        // Store the optional legacy preset index for older-format compatibility.
        self.progression = progression
        // Store the optional custom MIDI chord notes from the sandbox.
        self.chordNotes = chordNotes
        // Store the optional tempo in beats per minute.
        self.bpm = bpm
        // Store which drum-beat preset this idea uses.
        self.beat = beat
        // Store the creation date supplied by the caller.
        self.createdAt = createdAt
    }

    // Maps Swift property names to the keys used in the archived JSON data.
    private enum CodingKeys: String, CodingKey {
        // Lists every property that Codable should encode and decode.
        case id, title, progression, chordNotes, bpm, beat, createdAt
    }

    // Custom decoder keeps old saved songs readable when newer fields are missing.
    init(from decoder: Decoder) throws {
        // Ask the decoder for a container keyed by our CodingKeys.
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decode the id when present; otherwise create a fresh UUID for the song.
        id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        // Decode the title when present; otherwise use a friendly placeholder.
        title = (try? container.decode(String.self, forKey: .title)) ?? "Untitled"
        // Decode the legacy preset index optionally, since new songs may omit it.
        progression = try? container.decode(Int.self, forKey: .progression)
        // Decode custom MIDI triads optionally for songs saved with the sandbox.
        chordNotes = try? container.decode([[Int]].self, forKey: .chordNotes)
        // Decode tempo optionally so older songs can fall back to a default BPM.
        bpm = try? container.decode(Double.self, forKey: .bpm)
        // Decode the beat preset, defaulting to 0 for missing data.
        beat = (try? container.decode(Int.self, forKey: .beat)) ?? 0
        // Decode the timestamp, defaulting to now for older records without one.
        createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
    }
}

/// Persists song ideas in `UserDefaults`.
// This enum groups the small set of static helpers used to load and save songs.
enum SongLibrary {
    // The UserDefaults key under which the JSON array of songs is stored.
    static let key = "vinylStudioSongs"
    // Read the saved library from UserDefaults and decode it into model values.
    static func load() -> [SongIdea] {
        // Return an empty library when no data was ever saved for this key.
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        // Decode the JSON array, falling back to empty if the data is corrupt or outdated.
        return (try? JSONDecoder().decode([SongIdea].self, from: data)) ?? []
    }
    // Add a new idea to the front of the saved library so the newest appears first.
    static func save(_ song: SongIdea) {
        // Load the existing songs and insert the new one at index 0.
        var songs = load(); songs.insert(song, at: 0)
        // Encode the updated array as JSON and write it back to UserDefaults.
        if let data = try? JSONEncoder().encode(songs) { UserDefaults.standard.set(data, forKey: key) }
    }
}
