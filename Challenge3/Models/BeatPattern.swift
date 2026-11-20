import Foundation

/// An eight-step drum pattern.
struct BeatPattern: Identifiable {
    let id: Int
    let name: String
    let detail: String
    let steps: [[Int]]
}

// 0 = kick, 1 = snare, 2 = hi-hat; eight eighth-note steps per bar
let beats: [BeatPattern] = [
    .init(id: 0, name: "Pop", detail: "Classic backbeat", steps: [[0,2],[2],[1,2],[2],[0,2],[2],[1,2],[2]]),
    .init(id: 1, name: "Rock", detail: "Driving groove", steps: [[0,2],[2],[1,2],[0,2],[0,2],[0,2],[1,2],[0,2]]),
    .init(id: 2, name: "Dance", detail: "Four on the floor", steps: [[0,2],[2],[0,2],[1,2],[0,2],[2],[0,2],[1,2]]),
    .init(id: 3, name: "Hip-Hop", detail: "Laid-back bounce", steps: [[0,2],[],[1,2],[0],[2],[0,2],[1,2],[]]),
    .init(id: 4, name: "Ballad", detail: "Gentle and spacious", steps: [[0,2],[],[1],[2],[0,2],[],[1],[2]]),
    .init(id: 5, name: "Funk", detail: "Syncopated rhythm", steps: [[0,2],[2],[1,2],[0,2],[2],[0,2],[1,2],[0,2]])
]
