import Foundation

/// A four-chord progression with the notes used to synthesise it.
struct Progression: Identifiable {
    let id: Int
    let name: String
    let mood: String
    let chords: [String]
    let notes: [[Int]]
}

let progressions: [Progression] = [
    .init(id: 0, name: "Pop Classic", mood: "Bright and familiar", chords: ["C", "G", "Am", "F"], notes: [[60,64,67], [55,59,62], [57,60,64], [53,57,60]]),
    .init(id: 1, name: "Emotional", mood: "Reflective and warm", chords: ["Am", "F", "C", "G"], notes: [[57,60,64], [53,57,60], [60,64,67], [55,59,62]]),
    .init(id: 2, name: "Feel Good", mood: "Upbeat and hopeful", chords: ["F", "C", "G", "Am"], notes: [[53,57,60], [60,64,67], [55,59,62], [57,60,64]]),
    .init(id: 3, name: "Simple Loop", mood: "Calm and steady", chords: ["C", "Am", "F", "G"], notes: [[60,64,67], [57,60,64], [53,57,60], [55,59,62]]),
    .init(id: 4, name: "Doo-Wop", mood: "Nostalgic and sweet", chords: ["C", "Am", "F", "G"], notes: [[60,64,67], [57,60,64], [53,57,60], [55,59,62]]),
    .init(id: 5, name: "Jazz Turnaround", mood: "Smooth and sophisticated", chords: ["Dm", "G", "C", "Am"], notes: [[62,65,69], [55,59,62], [60,64,67], [57,60,64]]),
    .init(id: 6, name: "Canon", mood: "Elegant and flowing", chords: ["C", "G", "Am", "Em"], notes: [[60,64,67], [55,59,62], [57,60,64], [52,55,59]]),
    .init(id: 7, name: "Minor Drama", mood: "Brooding and intense", chords: ["Am", "G", "F", "E"], notes: [[57,60,64], [55,59,62], [53,57,60], [52,56,59]]),
    .init(id: 8, name: "Dreamy", mood: "Soft and floating", chords: ["C", "Em", "F", "G"], notes: [[60,64,67], [52,55,59], [53,57,60], [55,59,62]]),
    .init(id: 9, name: "Slow Ballad", mood: "Tender and open", chords: ["F", "Dm", "B♭", "C"], notes: [[53,57,60], [50,53,57], [58,62,65], [60,64,67]])
]
