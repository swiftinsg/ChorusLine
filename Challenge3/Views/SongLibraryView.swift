// -----------------------------------------------------------------------------
// FILE SUMMARY — Views/SongLibraryView.swift
// -----------------------------------------------------------------------------
// PURPOSE: Lists saved song ideas with their chord summary, beat and date;
//          supports preview playback and swipe-to-delete.
//
// HOW IT WORKS:
//   • body — a List seeded from `SongLibrary.load()`. Each row shows the title,
//     details and a Play button; onDelete removes rows and persists the new JSON
//     array to UserDefaults. Stops audio when the view disappears.
//   • play(_:) — safely resolves the stored beat, then plays either the custom
//     chordNotes (wrapped in a temporary Progression) or the legacy preset index,
//     using the saved BPM with a fallback of 108.
//   • chordSummary(for:) — builds an en-dash separated chord list from custom
//     notes or the built-in progression, with an "Unknown chords" fallback.
//   • chordLabel(for:) — sorts notes, names the root and appends "m" when a
//     minor third is present.
//   • Array subscript(safe:) — private extension returning nil instead of
//     trapping on out-of-range indices.
// -----------------------------------------------------------------------------

// Import SwiftUI for List, view modifiers, and the state property wrappers used below.
import SwiftUI

/// Lists, previews and deletes saved song ideas.
// Define the screen that lists saved song ideas and lets users preview or delete them.
struct SongLibraryView: View {
    // Create and own the audio engine with @StateObject so playback continues across view updates.
    @StateObject private var audio = MusicEngine()
    // Load saved songs from UserDefaults-backed storage into local @State so edits trigger redraws.
    @State private var songs = SongLibrary.load()
    // Build the list UI and its styling.
    var body: some View {
        // Use a List so rows support scrolling and swipe-to-delete out of the box.
        List {
            // Show a placeholder row when there are no saved songs to display.
            if songs.isEmpty {
                // Tell the user the library is empty instead of showing a blank screen.
                Text("No song ideas saved yet.")
                    // Dim the placeholder so it reads as secondary information.
                    .foregroundStyle(Palette.muted)
                    // Match the placeholder row background to the rest of the themed list.
                    .listRowBackground(Palette.panel)
            }
            // Create one row for each saved SongIdea, identified by its stored id.
            ForEach(songs) { song in
                // Stack the song details and play button vertically with left alignment.
                VStack(alignment: .leading, spacing: 6) {
                    // Show the song's title prominently as the row's main label.
                    Text(song.title).font(.headline)
                    // Summarize the chords and beat name, falling back to "Unknown" when the stored beat index is invalid.
                    Text("\(chordSummary(for: song)) · \(beats[safe: song.beat]?.name ?? "Unknown") beat")
                        // Use smaller, muted text so details sit below the title in the visual hierarchy.
                        .font(.caption).foregroundStyle(.secondary)
                    // Show when the idea was saved using the locale's standard date style.
                    Text(song.createdAt, style: .date).font(.caption2).foregroundStyle(.secondary)
                    // Provide a play control that previews the saved song through the audio engine.
                    Button("▶ Play song") {
                        // Call the helper that reconstructs the progression and starts playback.
                        play(song)
                    // Give the play control a standard bordered style so it looks tappable.
                    }.buttonStyle(.bordered)
                }
                // Apply the themed panel background behind each song row.
                .listRowBackground(Palette.panel)
            }
            // Handle swipe-to-delete by receiving the row offsets the user removed.
            .onDelete { offsets in
                // Remove the deleted songs from the local array so the list updates immediately.
                songs.remove(atOffsets: offsets)
                // Encode the updated array to JSON and persist it under SongLibrary.key in UserDefaults so deletions survive relaunch.
                if let data = try? JSONEncoder().encode(songs) { UserDefaults.standard.set(data, forKey: SongLibrary.key) }
            }
        }
        // Hide the default list background so the custom dark background shows through.
        .scrollContentBackground(.hidden)
        // Fill the entire screen behind the list, including safe-area insets, with the app background.
        .background(Palette.background.ignoresSafeArea())
        // Set the default text color to cream for contrast against the dark background.
        .foregroundStyle(Palette.cream)
        // Tint interactive controls such as the play button and delete action with the accent color.
        .tint(Palette.accent)
        // Title the screen and stop audio playback when the user leaves it.
        .navigationTitle("My Songs").onDisappear { audio.stop() }
    }

    // Rebuild a saved idea into playable data and start it with the shared audio engine.
    private func play(_ song: SongIdea) {
        // Use the safe subscript to avoid a crash if the stored beat index is out of range, then bail out if it is invalid.
        guard let beat = beats[safe: song.beat] else { return }
        // Prefer custom chord notes when the saved song contains them.
        if let notes = song.chordNotes, !notes.isEmpty {
            // Build a temporary progression with human-readable chord labels derived from the saved MIDI notes.
            let progression = Progression(id: -1, name: song.title, mood: "Custom", chords: notes.map(chordLabel(for:)), notes: notes)
            // Play the custom progression with the saved tempo, defaulting to 108 BPM.
            audio.playSong(progression: progression, beat: beat, bpm: song.bpm ?? 108)
        // Otherwise use a built-in progression if the saved index still exists in the catalog.
        } else if let index = song.progression, let progression = progressions[safe: index] {
            // Play the built-in progression with the saved tempo, again defaulting to 108 BPM.
            audio.playSong(progression: progression, beat: beat, bpm: song.bpm ?? 108)
        }
    }

    // Produce a short, readable chord list for the song row.
    private func chordSummary(for song: SongIdea) -> String {
        // Check whether the song saved explicit chord notes first.
        if let notes = song.chordNotes, !notes.isEmpty {
            // Convert each note group to a chord name and join them with an en dash.
            return notes.map(chordLabel(for:)).joined(separator: " – ")
        }
        // Fall back to a built-in progression when no custom notes exist.
        if let index = song.progression, let progression = progressions[safe: index] {
            // Join the built-in chord labels into the same en-dash separated format.
            return progression.chords.joined(separator: " – ")
        }
        // Return a friendly fallback when neither chord source is available.
        return "Unknown chords"
    }

    // Derive a simple root-and-quality chord name from an array of MIDI note numbers.
    private func chordLabel(for midiNotes: [Int]) -> String {
        // Map MIDI pitch classes (0–11) to conventional note names with sharps.
        let keyNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        // Sort the notes so the lowest pitch becomes the chord root.
        let ordered = midiNotes.sorted()
        // Return an empty label if the chord has no notes at all.
        guard let root = ordered.first else { return "" }
        // Wrap the root into 0–11 before indexing the note-name array, even for negative values.
        let rootName = keyNames[((root % 12) + 12) % 12]
        // Collect unique intervals above the root to detect chord quality without duplicates.
        let intervals = Set(ordered.map { $0 - root })
        // Treat a minor third (3 semitones) as a minor chord; otherwise assume major.
        let quality = intervals.contains(3) ? "m" : ""
        // Combine the root name and quality into a compact chord label.
        return rootName + quality
    }
}

// Add a safe indexed subscript to every array used in this file.
private extension Array {
    // Return an optional element instead of trapping when the index is out of bounds.
    subscript(safe index: Int) -> Element? {
        // Check the array's valid index range first, then return the element or nil.
        indices.contains(index) ? self[index] : nil
    }
}
