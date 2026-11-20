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
    .init(id: 0, name: "Pop Anthem", mood: "Big and catchy", chords: ["C", "G", "Am", "F"], notes: [[60,64,67], [55,59,62], [57,60,64], [53,57,60]]),
    .init(id: 1, name: "Radio Hit", mood: "Bright and driving", chords: ["G", "D", "Em", "C"], notes: [[55,59,62], [62,66,69], [52,55,59], [60,64,67]]),
    .init(id: 2, name: "Summer Pop", mood: "Sunny and upbeat", chords: ["D", "A", "Bm", "G"], notes: [[62,66,69], [57,61,64], [59,62,66], [55,59,62]]),
    .init(id: 3, name: "Indie Pop", mood: "Fresh and energetic", chords: ["A", "E", "F♯m", "D"], notes: [[57,61,64], [52,56,59], [54,57,61], [50,54,57]]),
    .init(id: 4, name: "Bright Pop", mood: "Shimmering and hopeful", chords: ["E", "B", "C♯m", "A"], notes: [[52,56,59], [59,63,66], [49,52,56], [57,61,64]]),
    .init(id: 5, name: "Feel-Good Pop", mood: "Warm and uplifting", chords: ["F", "C", "Dm", "B♭"], notes: [[53,57,60], [60,64,67], [50,53,57], [58,62,65]]),
    .init(id: 6, name: "Warm Pop", mood: "Smooth and soulful", chords: ["B♭", "F", "Gm", "E♭"], notes: [[58,62,65], [53,57,60], [55,58,62], [51,55,58]]),
    .init(id: 7, name: "Emotional Pop", mood: "Reflective and heartfelt", chords: ["Am", "F", "C", "G"], notes: [[57,60,64], [53,57,60], [60,64,67], [55,59,62]]),
    .init(id: 8, name: "Moody Pop", mood: "Cool and atmospheric", chords: ["Em", "C", "G", "D"], notes: [[52,55,59], [48,52,55], [55,59,62], [50,54,57]]),
    .init(id: 9, name: "Tender Pop", mood: "Soft and dreamy", chords: ["E♭", "B♭", "Cm", "A♭"], notes: [[51,55,58], [58,62,65], [48,51,55], [56,60,63]])
]
