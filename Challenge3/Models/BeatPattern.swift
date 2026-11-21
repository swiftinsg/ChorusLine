import Foundation

/// An eight-step drum pattern.
struct BeatPattern: Identifiable {
    let id: Int
    let name: String
    let detail: String
    /// Eight steps per bar; each step contains the drum hits to play at that step.
    let steps: [[Int]]
}

// Drum hit IDs: 0 = kick, 1 = snare, 2 = hi-hat. Each pattern has eight eighth-note steps.
let beats: [BeatPattern] = [
    .init(id: 0, name: "Classic Pop", detail: "Steady backbeat groove", steps: [[0,2],[2],[1,2],[2],[0,2],[2],[1,2],[2]]),
    .init(id: 1, name: "Dance Pop", detail: "Four-on-the-floor pulse", steps: [[0,2],[2],[0,1,2],[2],[0,2],[2],[0,1,2],[2]]),
    .init(id: 2, name: "Synth Pop", detail: "Bright driving rhythm", steps: [[0,2],[0,2],[1,2],[2],[0,2],[0,2],[1,2],[2]]),
    .init(id: 3, name: "Pop Rock", detail: "Punchy upbeat groove", steps: [[0,2],[2],[1,2],[0,2],[0,2],[2],[1,2],[0,2]]),
    .init(id: 4, name: "Pop Ballad", detail: "Soft and spacious feel", steps: [[0,2],[],[1,2],[],[0,2],[],[1,2],[]]),
    .init(id: 5, name: "R&B Pop", detail: "Smooth syncopated bounce", steps: [[0,2],[],[1,2],[0],[2],[0,2],[1,2],[2]])
]
