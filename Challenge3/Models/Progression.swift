import Foundation

/// A four-chord progression with the notes used to synthesise it.
/// - `chords`: display labels for each chord.
/// - `notes`: MIDI note numbers per chord (one array per bar/chord step), used by `MusicEngine`.
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
    .init(id: 6, name: "Classic Pop", mood: "Smooth and familiar", chords: ["B♭", "F", "Gm", "E♭"], notes: [[58,62,65], [53,57,60], [55,58,62], [51,55,58]]),
    .init(id: 7, name: "Dream Pop", mood: "Airy and emotional", chords: ["B", "F♯", "G♯m", "E"], notes: [[59,63,66], [54,58,61], [56,59,63], [52,56,59]]),
    .init(id: 8, name: "C Drive", mood: "Bright and driving", chords: ["Am", "F", "C", "G"], notes: [[66,69,73], [58,62,65], [60,64,67], [62,66,69]]),
    .init(id: 9, name: "C Lift", mood: "Warm and uplifting", chords: ["C", "F", "Am", "G"], notes: [[60,64,67], [58,62,65], [66,69,73], [62,66,69]]),
    .init(id: 10, name: "C Story", mood: "Reflective and flowing", chords: ["C", "Am", "Dm", "G"], notes: [[60,64,67], [66,69,73], [64,67,71], [62,66,69]]),
    .init(id: 11, name: "C Glow", mood: "Open and hopeful", chords: ["C", "G", "Dm", "F"], notes: [[60,64,67], [62,66,69], [64,67,71], [58,62,65]]),
    .init(id: 12, name: "C♯ Anthem", mood: "Big and catchy", chords: ["C♯", "G♯", "A♯m", "F♯"], notes: [[61,65,68], [63,67,70], [67,70,74], [59,63,66]]),
    .init(id: 13, name: "C♯ Drive", mood: "Bright and driving", chords: ["A♯m", "F♯", "C♯", "G♯"], notes: [[67,70,74], [59,63,66], [61,65,68], [63,67,70]]),
    .init(id: 14, name: "C♯ Lift", mood: "Warm and uplifting", chords: ["C♯", "F♯", "A♯m", "G♯"], notes: [[61,65,68], [59,63,66], [67,70,74], [63,67,70]]),
    .init(id: 15, name: "C♯ Story", mood: "Reflective and flowing", chords: ["C♯", "A♯m", "D♯m", "G♯"], notes: [[61,65,68], [67,70,74], [65,68,72], [63,67,70]]),
    .init(id: 16, name: "C♯ Glow", mood: "Open and hopeful", chords: ["C♯", "G♯", "D♯m", "F♯"], notes: [[61,65,68], [63,67,70], [65,68,72], [59,63,66]]),
    .init(id: 17, name: "D Drive", mood: "Bright and driving", chords: ["Bm", "G", "D", "A"], notes: [[68,71,75], [60,64,67], [62,66,69], [64,68,71]]),
    .init(id: 18, name: "D Lift", mood: "Warm and uplifting", chords: ["D", "G", "Bm", "A"], notes: [[62,66,69], [60,64,67], [68,71,75], [64,68,71]]),
    .init(id: 19, name: "D Story", mood: "Reflective and flowing", chords: ["D", "Bm", "Em", "A"], notes: [[62,66,69], [68,71,75], [66,69,73], [64,68,71]]),
    .init(id: 20, name: "D Glow", mood: "Open and hopeful", chords: ["D", "A", "Em", "G"], notes: [[62,66,69], [64,68,71], [66,69,73], [60,64,67]]),
    .init(id: 21, name: "D♯ Anthem", mood: "Big and catchy", chords: ["D♯", "A♯", "Cm", "G♯"], notes: [[63,67,70], [65,69,72], [69,72,76], [61,65,68]]),
    .init(id: 22, name: "D♯ Drive", mood: "Bright and driving", chords: ["Cm", "G♯", "D♯", "A♯"], notes: [[69,72,76], [61,65,68], [63,67,70], [65,69,72]]),
    .init(id: 23, name: "D♯ Lift", mood: "Warm and uplifting", chords: ["D♯", "G♯", "Cm", "A♯"], notes: [[63,67,70], [61,65,68], [69,72,76], [65,69,72]]),
    .init(id: 24, name: "D♯ Story", mood: "Reflective and flowing", chords: ["D♯", "Cm", "Fm", "A♯"], notes: [[63,67,70], [69,72,76], [67,70,74], [65,69,72]]),
    .init(id: 25, name: "D♯ Glow", mood: "Open and hopeful", chords: ["D♯", "A♯", "Fm", "G♯"], notes: [[63,67,70], [65,69,72], [67,70,74], [61,65,68]]),
    .init(id: 26, name: "E Drive", mood: "Bright and driving", chords: ["C♯m", "A", "E", "B"], notes: [[70,73,77], [62,66,69], [64,68,71], [66,70,73]]),
    .init(id: 27, name: "E Lift", mood: "Warm and uplifting", chords: ["E", "A", "C♯m", "B"], notes: [[64,68,71], [62,66,69], [70,73,77], [66,70,73]]),
    .init(id: 28, name: "E Story", mood: "Reflective and flowing", chords: ["E", "C♯m", "F♯m", "B"], notes: [[64,68,71], [70,73,77], [68,71,75], [66,70,73]]),
    .init(id: 29, name: "E Glow", mood: "Open and hopeful", chords: ["E", "B", "F♯m", "A"], notes: [[64,68,71], [66,70,73], [68,71,75], [62,66,69]]),
    .init(id: 30, name: "F Drive", mood: "Bright and driving", chords: ["Dm", "A♯", "F", "C"], notes: [[71,74,78], [63,67,70], [65,69,72], [67,71,74]]),
    .init(id: 31, name: "F Lift", mood: "Warm and uplifting", chords: ["F", "A♯", "Dm", "C"], notes: [[65,69,72], [63,67,70], [71,74,78], [67,71,74]]),
    .init(id: 32, name: "F Story", mood: "Reflective and flowing", chords: ["F", "Dm", "Gm", "C"], notes: [[65,69,72], [71,74,78], [69,72,76], [67,71,74]]),
    .init(id: 33, name: "F Glow", mood: "Open and hopeful", chords: ["F", "C", "Gm", "A♯"], notes: [[65,69,72], [67,71,74], [69,72,76], [63,67,70]]),
    .init(id: 34, name: "F♯ Anthem", mood: "Big and catchy", chords: ["F♯", "C♯", "D♯m", "B"], notes: [[66,70,73], [68,72,75], [72,75,79], [64,68,71]]),
    .init(id: 35, name: "F♯ Drive", mood: "Bright and driving", chords: ["D♯m", "B", "F♯", "C♯"], notes: [[72,75,79], [64,68,71], [66,70,73], [68,72,75]]),
    .init(id: 36, name: "F♯ Lift", mood: "Warm and uplifting", chords: ["F♯", "B", "D♯m", "C♯"], notes: [[66,70,73], [64,68,71], [72,75,79], [68,72,75]]),
    .init(id: 37, name: "F♯ Story", mood: "Reflective and flowing", chords: ["F♯", "D♯m", "G♯m", "C♯"], notes: [[66,70,73], [72,75,79], [70,73,77], [68,72,75]]),
    .init(id: 38, name: "F♯ Glow", mood: "Open and hopeful", chords: ["F♯", "C♯", "G♯m", "B"], notes: [[66,70,73], [68,72,75], [70,73,77], [64,68,71]]),
    .init(id: 39, name: "G Drive", mood: "Bright and driving", chords: ["Em", "C", "G", "D"], notes: [[73,76,80], [65,69,72], [67,71,74], [69,73,76]]),
    .init(id: 40, name: "G Lift", mood: "Warm and uplifting", chords: ["G", "C", "Em", "D"], notes: [[67,71,74], [65,69,72], [73,76,80], [69,73,76]]),
    .init(id: 41, name: "G Story", mood: "Reflective and flowing", chords: ["G", "Em", "Am", "D"], notes: [[67,71,74], [73,76,80], [71,74,78], [69,73,76]]),
    .init(id: 42, name: "G Glow", mood: "Open and hopeful", chords: ["G", "D", "Am", "C"], notes: [[67,71,74], [69,73,76], [71,74,78], [65,69,72]]),
    .init(id: 43, name: "G♯ Anthem", mood: "Big and catchy", chords: ["G♯", "D♯", "Fm", "C♯"], notes: [[68,72,75], [70,74,77], [74,77,81], [66,70,73]]),
    .init(id: 44, name: "G♯ Drive", mood: "Bright and driving", chords: ["Fm", "C♯", "G♯", "D♯"], notes: [[74,77,81], [66,70,73], [68,72,75], [70,74,77]]),
    .init(id: 45, name: "G♯ Lift", mood: "Warm and uplifting", chords: ["G♯", "C♯", "Fm", "D♯"], notes: [[68,72,75], [66,70,73], [74,77,81], [70,74,77]]),
    .init(id: 46, name: "G♯ Story", mood: "Reflective and flowing", chords: ["G♯", "Fm", "A♯m", "D♯"], notes: [[68,72,75], [74,77,81], [72,75,79], [70,74,77]]),
    .init(id: 47, name: "G♯ Glow", mood: "Open and hopeful", chords: ["G♯", "D♯", "A♯m", "C♯"], notes: [[68,72,75], [70,74,77], [72,75,79], [66,70,73]]),
    .init(id: 48, name: "A Drive", mood: "Bright and driving", chords: ["F♯m", "D", "A", "E"], notes: [[75,78,82], [67,71,74], [69,73,76], [71,75,78]]),
    .init(id: 49, name: "A Lift", mood: "Warm and uplifting", chords: ["A", "D", "F♯m", "E"], notes: [[69,73,76], [67,71,74], [75,78,82], [71,75,78]]),
    .init(id: 50, name: "A Story", mood: "Reflective and flowing", chords: ["A", "F♯m", "Bm", "E"], notes: [[69,73,76], [75,78,82], [73,76,80], [71,75,78]]),
    .init(id: 51, name: "A Glow", mood: "Open and hopeful", chords: ["A", "E", "Bm", "D"], notes: [[69,73,76], [71,75,78], [73,76,80], [67,71,74]]),
    .init(id: 52, name: "A♯ Drive", mood: "Bright and driving", chords: ["Gm", "D♯", "A♯", "F"], notes: [[76,79,83], [68,72,75], [70,74,77], [72,76,79]]),
    .init(id: 53, name: "A♯ Lift", mood: "Warm and uplifting", chords: ["A♯", "D♯", "Gm", "F"], notes: [[70,74,77], [68,72,75], [76,79,83], [72,76,79]]),
    .init(id: 54, name: "A♯ Story", mood: "Reflective and flowing", chords: ["A♯", "Gm", "Cm", "F"], notes: [[70,74,77], [76,79,83], [74,77,81], [72,76,79]]),
    .init(id: 55, name: "A♯ Glow", mood: "Open and hopeful", chords: ["A♯", "F", "Cm", "D♯"], notes: [[70,74,77], [72,76,79], [74,77,81], [68,72,75]]),
    .init(id: 56, name: "B Drive", mood: "Bright and driving", chords: ["G♯m", "E", "B", "F♯"], notes: [[77,80,84], [69,73,76], [71,75,78], [73,77,80]]),
    .init(id: 57, name: "B Lift", mood: "Warm and uplifting", chords: ["B", "E", "G♯m", "F♯"], notes: [[71,75,78], [69,73,76], [77,80,84], [73,77,80]]),
    .init(id: 58, name: "B Story", mood: "Reflective and flowing", chords: ["B", "G♯m", "C♯m", "F♯"], notes: [[71,75,78], [77,80,84], [75,78,82], [73,77,80]]),
    .init(id: 59, name: "B Glow", mood: "Open and hopeful", chords: ["B", "F♯", "C♯m", "E"], notes: [[71,75,78], [73,77,80], [75,78,82], [69,73,76]])
]
