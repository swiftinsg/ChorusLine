// Import Foundation for the basic value types used by this data model.
import Foundation

/// An eight-step drum pattern.
// Conforms to Identifiable so SwiftUI lists and ForEach can distinguish each preset.
struct BeatPattern: Identifiable {
    // Stable identifier for the pattern, used by pickers and stored song ideas.
    let id: Int
    // Human-readable name shown in the pattern picker.
    let name: String
    // Short description that hints at the groove's feel.
    let detail: String
    // Eight steps, each listing the drum hit codes that fire on that step.
    let steps: [[Int]]
}

// 0 = kick, 1 = snare, 2 = hi-hat; eight eighth-note steps per bar
// Each inner array lists every drum that strikes on that step; an empty array is a rest.
let beats: [BeatPattern] = [
    // Classic Pop: steady kick on steps 1 and 5, snare on 3 and 7, hats throughout.
    .init(id: 0, name: "Classic Pop", detail: "Steady backbeat groove", steps: [[0,2],[2],[1,2],[2],[0,2],[2],[1,2],[2]]),
    // Dance Pop: four-on-the-floor kick on every even-numbered step for a driving pulse.
    .init(id: 1, name: "Dance Pop", detail: "Four-on-the-floor pulse", steps: [[0,2],[2],[0,1,2],[2],[0,2],[2],[0,1,2],[2]]),
    // Synth Pop: extra kicks on steps 2 and 6 keep the bright rhythm moving forward.
    .init(id: 2, name: "Synth Pop", detail: "Bright driving rhythm", steps: [[0,2],[0,2],[1,2],[2],[0,2],[0,2],[1,2],[2]]),
    // Pop Rock: punchy kicks with offbeat hats and a snare on steps 3 and 7.
    .init(id: 3, name: "Pop Rock", detail: "Punchy upbeat groove", steps: [[0,2],[2],[1,2],[0,2],[0,2],[2],[1,2],[0,2]]),
    // Pop Ballad: sparse hits with alternating silent steps for a spacious feel.
    .init(id: 4, name: "Pop Ballad", detail: "Soft and spacious feel", steps: [[0,2],[],[1,2],[],[0,2],[],[1,2],[]]),
    // R&B Pop: syncopated kick and snare placements create a smooth bounce.
    .init(id: 5, name: "R&B Pop", detail: "Smooth syncopated bounce", steps: [[0,2],[],[1,2],[0],[2],[0,2],[1,2],[2]])
]
