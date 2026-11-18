import SwiftUI
import Combine
import UIKit
import AVFoundation

// MARK: - Shared progress
final class StudioState: ObservableObject {
    @Published var completed: Set<Int> = Set(UserDefaults.standard.array(forKey: "completedModules") as? [Int] ?? []) {
        didSet { UserDefaults.standard.set(Array(completed), forKey: "completedModules") }
    }
    @Published var completionEvent: Int? = nil
    @Published var selectedProgression = 0
    @Published var selectedBeat = 0
    func finish(_ module: Int) { completionEvent = module; completed.insert(module) }
}

enum Palette {
    static let background = Color(red: 0.075, green: 0.082, blue: 0.12)
    static let panel = Color(red: 0.13, green: 0.15, blue: 0.21)
    static let gold = Color(red: 0.92, green: 0.72, blue: 0.36)
    static let cream = Color(red: 0.96, green: 0.94, blue: 0.88)
}

struct Vinyl: View {
    var color: Color = .purple
    var spinning = false
    var size: CGFloat = 132
    var showCenterDot = true
    @State private var rotation = 0.0
    @State private var dropped = false
    var body: some View {
        ZStack {
            Circle().fill(Color.gray.opacity(0.35)).padding(-5)
            Circle().fill(Color.black)
            ForEach(0..<7, id: \.self) { i in
                Circle().stroke(Color.white.opacity(0.055), lineWidth: 1)
                    .padding(CGFloat(i) * 8 + 7)
            }
            Circle().fill(color.gradient).padding(size * 0.29)
            Circle().stroke(.white.opacity(0.25), lineWidth: 1).padding(size * 0.33)
            if showCenterDot { Circle().fill(Palette.cream).frame(width: 9, height: 9) }
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(rotation))
        .scaleEffect(dropped ? 1 : 1.12)
        .offset(y: dropped ? 0 : -13)
        .shadow(color: color.opacity(0.25), radius: 16)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) { dropped = true }
            if spinning { start() }
        }
        .onChange(of: spinning) { _, value in
            dropped = false
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) { dropped = true }
            if value { start() } else { rotation = 0 }
        }
    }
    private func start() {
        rotation = 0
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) { rotation = 360 }
    }
}

struct HomeView: View {
    @StateObject private var state = StudioState()
    @State private var finishingModule: Int? = nil
    @State private var completionStage = 0
    @State private var openingModule: Int? = nil
    @State private var openingStage = 0
    @State private var path: [Int] = []
    private let titles = ["Song Structure", "Chord Progression", "Drum Beats", "Melody"]
    private let subtitles = ["Learn how songs are built", "Play chords on a piano", "Explore popular rhythms", "Find your own sound"]
    private let colors: [Color] = [.purple, .cyan, .orange, .mint]
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 25) {
                    VStack(spacing: 5) {
                        Text("VINYL STUDIO").font(.system(size: 33, weight: .black, design: .rounded)).tracking(3)
                        Text("Learn it. Spin it. Make it yours.").foregroundStyle(.white.opacity(0.65))
                    }.padding(.top, 28)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                        ForEach(0..<4) { index in
                            Button { openModule(index) } label: {
                                VStack(spacing: 11) {
                                    Vinyl(color: colors[index], spinning: state.completed.contains(index), size: 126)
                                    Text(titles[index]).font(.system(size: 15, weight: .bold))
                                    Text(state.completed.contains(index) ? "COMPLETED ✓" : subtitles[index])
                                        .font(.caption2).foregroundStyle(state.completed.contains(index) ? .green : .gray)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 19)
                                .background(Palette.panel, in: RoundedRectangle(cornerRadius: 20))
                            }.buttonStyle(.plain)
                        }
                    }
                    Button { openModule(4) } label: {
                        VStack(spacing: 12) {
                            Vinyl(color: Palette.gold, spinning: state.completed.contains(4), size: 150)
                            Text("GOLDEN SANDBOX").font(.title3.bold()).tracking(2)
                            Text("Mix chords and drum beats into your song")
                                .font(.subheadline).foregroundStyle(.white.opacity(0.65))
                        }.frame(maxWidth: .infinity).padding(23)
                            .background(Palette.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 22))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.gold.opacity(0.35)))
                    }.buttonStyle(.plain)
                }.padding(20)
            }
            .background(Palette.background).foregroundStyle(Palette.cream)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Int.self) { index in
                Group {
                    switch index {
                    case 0: StructureView()
                    case 1: ChordLessonView()
                    case 2: DrumLessonView()
                    case 3: MelodyView()
                    default: SandboxView()
                    }
                }.environmentObject(state)
            }
        }
        .tint(Palette.gold)
        .overlay {
            if let module = openingModule {
                OpeningRecordAnimation(color: module == 4 ? Palette.gold : colors[module], stage: openingStage)
                    .transition(.opacity).allowsHitTesting(true)
            }
            if let module = finishingModule {
                RecordPlayerCompletion(color: module == 4 ? Palette.gold : colors[module], stage: completionStage)
                    .transition(.opacity).allowsHitTesting(true)
            }
        }
        .onChange(of: state.completionEvent) { _, module in
            guard let module else { return }
            finishingModule = module
            completionStage = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.easeOut(duration: 0.65)) { completionStage = 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                withAnimation(.spring(response: 0.9, dampingFraction: 0.72)) { completionStage = 2 }
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                withAnimation(.easeOut(duration: 0.35)) { finishingModule = nil }
                state.completionEvent = nil
            }
        }
    }
    private func openModule(_ index: Int) {
        guard openingModule == nil && finishingModule == nil else { return }
        openingModule = index
        openingStage = 0
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.85)) { openingStage = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            path.append(index)
            withAnimation(.easeOut(duration: 0.25)) { openingModule = nil }
        }
    }
}

struct OpeningRecordAnimation: View {
    let color: Color
    let stage: Int
    var body: some View {
        ZStack {
            Palette.background.opacity(0.97).ignoresSafeArea()
            VStack(spacing: 26) {
                Text("NOW LOADING").font(.headline).tracking(4).foregroundStyle(Palette.gold)
                Vinyl(color: color, spinning: true, size: 220)
                    .scaleEffect(stage == 0 ? 0.48 : 1.38)
                    .rotationEffect(.degrees(stage == 0 ? 0 : 110))
                    .shadow(color: color.opacity(0.55), radius: 35)
                Text("Dropping the needle…").foregroundStyle(Palette.cream)
            }
        }
    }
}

// A record grows, tilts in 3D, and settles on a turntable when a module is finished.
struct RecordPlayerCompletion: View {
    let color: Color
    let stage: Int

    // The record and the platter share ONE perspective transform. This prevents
    // a horizontal-looking record from landing on a face-on record player.
    var body: some View {
        GeometryReader { geometry in
            let deckWidth = min(geometry.size.width - 36, 340.0)
            ZStack {
                Palette.background.opacity(0.97).ignoresSafeArea()
                VStack(spacing: 24) {
                    Text("MODULE COMPLETE!")
                        .font(.title2.bold()).foregroundStyle(Palette.gold)

                    ZStack {
                        // Cast shadow underneath the floating 3D turntable.
                        Ellipse().fill(.black.opacity(0.48))
                            .frame(width: deckWidth * 0.94, height: 65)
                            .blur(radius: 23).offset(y: 140)

                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(LinearGradient(colors: [Color(white: 0.31), Palette.panel, Color(white: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Palette.gold.opacity(0.55), lineWidth: 2)
                                }
                                .shadow(color: .black.opacity(0.7), radius: 12, y: 12)

                            Circle().fill(Color(white: 0.055))
                                .frame(width: deckWidth * 0.77, height: deckWidth * 0.77)
                                .overlay {
                                    Circle().stroke(Color.gray.opacity(0.7), lineWidth: 5)
                                }
                                .offset(x: -12, y: -8)

                            // The record lifts up, expands, then drops vertically
                            // onto the platter, all within the same tilted plane.
                            Vinyl(color: color, spinning: stage == 2, size: deckWidth * 0.66)
                                .scaleEffect(stage == 0 ? 0.72 : stage == 1 ? 1.27 : 1)
                                .offset(x: -12, y: stage == 2 ? -8 : -105)
                                .shadow(color: .black.opacity(0.7), radius: stage == 2 ? 3 : 22, y: stage == 2 ? 2 : 30)

                            // Tonearm sits above the platter, in the SAME plane.
                            Path { path in
                                path.move(to: CGPoint(x: deckWidth * 0.84, y: deckWidth * 0.17))
                                path.addLine(to: CGPoint(x: deckWidth * 0.73, y: deckWidth * 0.30))
                                path.addLine(to: CGPoint(x: deckWidth * 0.65, y: deckWidth * 0.50))
                            }
                            .stroke(Palette.gold, style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
                            Circle().fill(Palette.cream)
                                .frame(width: 16, height: 16)
                                .position(x: deckWidth * 0.84, y: deckWidth * 0.17)
                        }
                        .frame(width: deckWidth, height: deckWidth)
                        .rotation3DEffect(.degrees(55), axis: (x: 1, y: 0, z: 0), perspective: 0.65)
                        .rotation3DEffect(.degrees(-13), axis: (x: 0, y: 1, z: 0), perspective: 0.45)
                    }
                    .frame(height: deckWidth * 0.90 + 65)

                    Text(stage == 2 ? "Record loaded. Keep creating!" : "Loading your record…")
                        .foregroundStyle(Palette.cream)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct LessonCard: View {
    let title: String
    let description: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title2.bold()).foregroundStyle(Palette.gold)
            Text(description).font(.body).foregroundStyle(Palette.cream)
                .fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
            .padding(22).background(Palette.panel, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct PrimaryAction: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.headline).frame(maxWidth: .infinity).padding(17)
                .background(Palette.gold, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(Palette.background)
        }
    }
}

struct LessonBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.background(Palette.background).foregroundStyle(Palette.cream)
            .navigationBarTitleDisplayMode(.inline)
    }
}

// Measures actual angular movement around the center of the vinyl.
// Clockwise turns are positive in screen coordinates (y increases downwards).
struct CircularVinylGesture: ViewModifier {
    let diameter: CGFloat
    let onStep: (Int) -> Void
    @State private var previousAngle: Double? = nil
    @State private var accumulated = 0.0
    func body(content: Content) -> some View {
        content.contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 3, coordinateSpace: .local)
                .onChanged { value in
                    let center = CGPoint(x: diameter / 2, y: diameter / 2)
                    let x = value.location.x - center.x
                    let y = value.location.y - center.y
                    guard hypot(x, y) > diameter * 0.15 else { return }
                    let angle = atan2(y, x) * 180 / .pi
                    if let previousAngle {
                        var delta = angle - previousAngle
                        if delta > 180 { delta -= 360 }
                        if delta < -180 { delta += 360 }
                        accumulated += delta
                        while accumulated >= 65 {
                            onStep(1); accumulated -= 65
                        }
                        while accumulated <= -65 {
                            onStep(-1); accumulated += 65
                        }
                    }
                    previousAngle = angle
                }
                .onEnded { _ in previousAngle = nil; accumulated = 0 })
    }
}

struct StructureView: View {
    @EnvironmentObject var state: StudioState
    @State private var page = 0
    @State private var quiz = false
    @State private var showSpinTip = false
    @State private var rotation = 0.0
    @State private var introScale = 0.6
    private let lessons: [(String, String)] = [
        ("INTRO", "The opening sets the mood and draws listeners into the song. Some intros introduce the main hook."),
        ("VERSE 1", "The first verse introduces the story, setting, or emotion. It usually has a more restrained melody than the chorus."),
        ("PRE-CHORUS", "A short build-up that increases tension and leads naturally into the chorus."),
        ("CHORUS", "The central repeated section, often containing the strongest hook and the song's main message."),
        ("VERSE 2", "Develops the story with new details while keeping a familiar musical pattern."),
        ("BRIDGE", "A contrasting section that adds variety or a fresh perspective before the final chorus."),
        ("OUTRO", "The ending provides a sense of closure, perhaps repeating a hook or fading out.")
    ]
    var body: some View {
        VStack(spacing: 18) {
            if quiz {
                StructureQuiz().environmentObject(state)
            } else {
                Text("SONG STRUCTURE").font(.title.bold()).padding(.top)
                ProgressView(value: Double(page + 1), total: Double(lessons.count))
                    .tint(Palette.gold).accessibilityLabel("Lesson progress")
                ScrollView {
                    LessonCard(title: lessons[page].0, description: lessons[page].1)
                        .id(page)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
                Spacer(minLength: 0)
                Text(page == lessons.count - 1 ? "Spin clockwise to start the quiz" : "Spin clockwise to turn the page")
                    .font(.caption).foregroundStyle(.gray).multilineTextAlignment(.center)

                // Only the TOP HALF of the record is visible, emerging from the
                // bottom edge. The entire disc retains its circular drag gesture.
                Vinyl(color: .purple, size: 270)
                    .rotationEffect(.degrees(rotation))
                    .modifier(CircularVinylGesture(diameter: 270) { direction in
                        withAnimation(.easeOut(duration: 0.25)) { rotation += Double(direction) * 65 }
                        UISelectionFeedbackGenerator().selectionChanged()
                        guard direction > 0 else { return }
                        if page < lessons.count - 1 {
                            withAnimation(.easeInOut(duration: 0.3)) { page += 1 }
                        } else { withAnimation { quiz = true } }
                    })
                    .scaleEffect(introScale)
                    .frame(height: 135, alignment: .top)
                    .clipped()
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Half vinyl record. Rotate clockwise for next lesson")
            }
        }
        .padding(.horizontal, 20).padding(.top, 20).modifier(LessonBackground()).navigationTitle("Module 1")
        .onAppear {
            showSpinTip = !quiz && page == 0
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) { introScale = 1 }
        }
        .alert("Spin the Vinyl!", isPresented: $showSpinTip) {
            Button("Let's Spin!", role: .cancel) { }
        } message: {
            Text("Place your finger near the outer edge of the record and move it clockwise to turn the lesson pages. Complete all sections to unlock the quiz.")
        }
    }
}

struct StructureQuiz: View {
    @EnvironmentObject var state: StudioState
    @Environment(\.dismiss) private var dismiss
    @State private var question = 0
    @State private var selected = 0
    @State private var rotation = 0.0
    @State private var revealed = false
    @State private var feedback = ""
    private let questions: [(String, [String], Int)] = [
        ("Which section usually contains the main repeated hook?", ["Verse", "Chorus", "Bridge", "Outro"], 1),
        ("What does a pre-chorus typically do?", ["End the song", "Introduce credits", "Build into the chorus", "Replace the beat"], 2),
        ("Which section often offers a musical contrast?", ["Bridge", "Verse 2", "Intro", "Outro"], 0)
    ]
    var body: some View {
        VStack(spacing: 22) {
            Text("SPIN THE ANSWERS").font(.title2.bold())
            ProgressView(value: Double(question + 1), total: Double(questions.count))
                .tint(Palette.gold).accessibilityLabel("Quiz progress")
            Text(questions[question].0).font(.title3.bold()).multilineTextAlignment(.center)
            ZStack {
                Vinyl(color: .purple, size: 245, showCenterDot: false)
                    .rotationEffect(.degrees(rotation))
                VStack(spacing: 8) {
                    Text("ANSWER").font(.caption2.bold()).tracking(2)
                    Text(questions[question].1[selected]).font(.headline)
                        .multilineTextAlignment(.center).frame(width: 125)
                }.foregroundStyle(.white).allowsHitTesting(false)
            }
            .modifier(CircularVinylGesture(diameter: 245) { direction in
                withAnimation(.easeOut(duration: 0.25)) { rotation += Double(direction) * 65 }
                selected = (selected + direction + 4) % 4
                UISelectionFeedbackGenerator().selectionChanged()
                revealed = false; feedback = ""
            })
            Text("Move your finger around the edge of the vinyl to choose an answer")
                .font(.caption).foregroundStyle(.gray).multilineTextAlignment(.center)
            if !feedback.isEmpty { Text(feedback).foregroundStyle(feedback == "Correct!" ? .green : .orange) }
            Spacer()
            PrimaryAction(title: revealed && selected == questions[question].2 ? (question == questions.count - 1 ? "Finish Module" : "Next Question") : "Check Answer") {
                if revealed && selected == questions[question].2 {
                    if question == questions.count - 1 { state.finish(0); DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { dismiss() } }
                    else { question += 1; revealed = false; feedback = ""; selected = 0 }
                } else {
                    revealed = true
                    feedback = selected == questions[question].2 ? "Correct!" : "Not quite — spin and try again."
                }
            }
        }.padding().modifier(LessonBackground())
    }
}

// MARK: - Audio synthesizer (no external sound files needed)
final class MusicEngine: ObservableObject {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
    private var running = false
    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        do { try engine.start(); player.play(); running = true } catch { print("Audio engine: \(error)") }
    }
    func playChord(_ notes: [Int], duration: Double = 0.75) {
        guard running else { return }
        let sampleRate = 44100.0
        let count = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else { return }
        buffer.frameLength = count
        guard let left = buffer.floatChannelData?[0], let right = buffer.floatChannelData?[1] else { return }
        for i in 0..<Int(count) {
            let t = Double(i) / sampleRate
            let attack = min(1, t / 0.015)
            let release = min(1, (duration - t) / 0.12)
            let envelope = max(0, min(attack, release)) * exp(-t * 1.0)
            let wave = notes.reduce(0.0) { sum, midi in
                let frequency = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
                return sum + sin(2 * .pi * frequency * t) + 0.22 * sin(4 * .pi * frequency * t)
            } / Double(max(1, notes.count))
            let value = Float(wave * envelope * 0.22)
            left[i] = value; right[i] = value
        }
        player.scheduleBuffer(buffer, completionHandler: nil)
    }
    func playBeat(_ steps: [[Int]], bpm: Double = 105) {
        guard running else { return }
        let sampleRate = 44100.0
        let secondsPerStep = 60.0 / bpm / 2.0
        let duration = secondsPerStep * Double(steps.count)
        let count = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else { return }
        buffer.frameLength = count
        guard let left = buffer.floatChannelData?[0], let right = buffer.floatChannelData?[1] else { return }
        for i in 0..<Int(count) {
            let t = Double(i) / sampleRate
            let step = min(steps.count - 1, Int(t / secondsPerStep))
            let local = t - Double(step) * secondsPerStep
            var signal = 0.0
            let hits = steps[step]
            if hits.contains(0) { signal += sin(2 * .pi * (55 + 95 * exp(-local * 28)) * local) * exp(-local * 24) * 0.7 }
            if hits.contains(1) {
                let noise = sin(Double(i) * 83.37) * sin(Double(i) * 17.13)
                signal += noise * exp(-local * 26) * 0.48
            }
            if hits.contains(2) {
                let noise = sin(Double(i) * 59.17) * sin(Double(i) * 103.9)
                signal += noise * exp(-local * 85) * 0.22
            }
            let value = Float(max(-0.9, min(0.9, signal)))
            left[i] = value; right[i] = value
        }
        player.scheduleBuffer(buffer, completionHandler: nil)
    }
    func playSong(progression: Progression, beat: BeatPattern, bpm: Double = 108) {
        guard running else { return }
        stop()
        let rate = 44100.0
        let beatDuration = 60.0 / bpm
        let barDuration = 4 * beatDuration
        let duration = 4 * barDuration
        let frames = AVAudioFrameCount(duration * rate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let channels = buffer.floatChannelData else { return }
        buffer.frameLength = frames
        for i in 0..<Int(frames) {
            let t = Double(i) / rate
            let bar = min(3, Int(t / barDuration))
            let chordTime = t - Double(bar) * barDuration
            let notes = progression.notes[bar]
            let chordEnvelope = min(1, chordTime / 0.03) * min(1, (barDuration - chordTime) / 0.18)
            let chord = notes.reduce(0.0) { partial, midi in
                let frequency = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
                return partial + sin(2 * .pi * frequency * chordTime)
                    + 0.18 * sin(4 * .pi * frequency * chordTime)
            } / Double(max(1, notes.count)) * chordEnvelope * 0.22
            let stepDuration = beatDuration / 2
            let step = Int(t / stepDuration) % beat.steps.count
            let local = t.truncatingRemainder(dividingBy: stepDuration)
            let hits = beat.steps[step]
            var drums = 0.0
            if hits.contains(0) { drums += sin(2 * .pi * (58 + 85 * exp(-local * 26)) * local) * exp(-local * 25) * 0.52 }
            if hits.contains(1) { drums += sin(Double(i) * 83.37) * sin(Double(i) * 17.13) * exp(-local * 27) * 0.32 }
            if hits.contains(2) { drums += sin(Double(i) * 59.17) * sin(Double(i) * 103.9) * exp(-local * 92) * 0.14 }
            let value = Float(max(-0.9, min(0.9, chord + drums)))
            channels[0][i] = value
            channels[1][i] = value
        }
        player.scheduleBuffer(buffer, completionHandler: nil)
    }
    func stop() { player.stop(); player.play() }
}

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
    .init(id: 3, name: "Simple Loop", mood: "Calm and steady", chords: ["C", "Am", "F", "G"], notes: [[60,64,67], [57,60,64], [53,57,60], [55,59,62]])
]

struct ChordLessonView: View {
    @EnvironmentObject var state: StudioState
    @State private var showPiano = false
    var body: some View {
        Group {
            if showPiano { PianoView().environmentObject(state) }
            else {
                ScrollView { VStack(spacing: 20) {
                    Text("CHORD PROGRESSIONS").font(.title2.bold())
                    Vinyl(color: .cyan, size: 150)
                    LessonCard(title: "What is a chord?", description: "A chord is a group of notes played together. Different combinations create different feelings.")
                    LessonCard(title: "What is a progression?", description: "A chord progression is a sequence of chords repeated through part of a song. Try C–G–Am–F, a common pop progression.")
                    LessonCard(title: "How to use the piano", description: "Choose a progression, then tap its chord buttons to hear them. Use Play All to hear the full sequence.")
                    Spacer()
                    PrimaryAction(title: "Open Piano") { showPiano = true }
                }.padding() }
            }
        }.modifier(LessonBackground()).navigationTitle("Module 2")
    }
}

struct PianoView: View {
    @EnvironmentObject var state: StudioState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audio = MusicEngine()
    @State private var chosen = 0
    @State private var playing = false
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("CHORD PIANO").font(.title.bold())
                Text("Pick a progression and tap to hear it.").foregroundStyle(.gray)
                ForEach(progressions) { progression in
                    Button {
                        chosen = progression.id
                        state.selectedProgression = chosen
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(progression.name).font(.headline)
                                Text(progression.chords.joined(separator: "  –  ")).font(.subheadline)
                                Text(progression.mood).font(.caption).foregroundStyle(.gray)
                            }
                            Spacer()
                            if chosen == progression.id { Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.gold) }
                        }.padding().background(Palette.panel, in: RoundedRectangle(cornerRadius: 14))
                    }.buttonStyle(.plain)
                }
                Text("TAP THE CHORD KEYS").font(.caption.bold()).tracking(2)
                HStack(spacing: 7) {
                    ForEach(0..<4, id: \.self) { index in
                        Button {
                            audio.playChord(progressions[chosen].notes[index])
                        } label: {
                            VStack {
                                Text(progressions[chosen].chords[index]).font(.title3.bold())
                                Spacer()
                                Image(systemName: "music.note").font(.caption)
                            }
                            .foregroundStyle(Palette.background)
                            .frame(maxWidth: .infinity).frame(height: 150).padding(.vertical, 12)
                            .background(.white, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                PrimaryAction(title: "▶ Play All Chords") { playAll() }
                PrimaryAction(title: "Done — Complete Module") { audio.stop(); state.finish(1); DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { dismiss() } }
            }.padding()
        }.modifier(LessonBackground()).onDisappear { audio.stop() }
    }
    private func playAll() {
        audio.stop()
        for notes in progressions[chosen].notes { audio.playChord(notes, duration: 0.65) }
    }
}

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

struct DrumLessonView: View {
    @EnvironmentObject var state: StudioState
    @State private var showPads = false
    var body: some View {
        Group {
            if showPads { DrumPadsView().environmentObject(state) }
            else {
                ScrollView { VStack(spacing: 22) {
                    Text("DRUM BEATS").font(.title.bold())
                    Vinyl(color: .orange, size: 165)
                    LessonCard(title: "Rhythm is the heartbeat", description: "A drum beat sets the pulse and energy of a song. Kick drums create the low thump, snares add a sharp backbeat, and hi-hats mark smaller subdivisions.")
                    LessonCard(title: "Explore six grooves", description: "Pop, rock, dance, hip-hop, ballad and funk use different patterns. Tap each pad to hear its rhythm and discover what fits your song.")
                    Spacer()
                    PrimaryAction(title: "Explore Drum Pads") { showPads = true }
                }.padding() }
            }
        }.modifier(LessonBackground()).navigationTitle("Module 3")
    }
}

struct DrumPadsView: View {
    @EnvironmentObject var state: StudioState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audio = MusicEngine()
    @State private var selected = 0
    var body: some View {
        ScrollView { VStack(spacing: 24) {
            Text("BEAT MACHINE").font(.title.bold())
            Text("Tap a pad to play its beat").foregroundStyle(.gray)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(beats) { beat in
                    Button {
                        selected = beat.id; state.selectedBeat = selected
                        audio.stop(); audio.playBeat(beat.steps)
                    } label: {
                        VStack(spacing: 13) {
                            Image(systemName: "waveform").font(.largeTitle)
                            Text(beat.name).font(.headline)
                            Text(beat.detail).font(.caption).foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        }.frame(maxWidth: .infinity).frame(height: 125)
                            .background(selected == beat.id ? Color.orange.opacity(0.45) : Palette.panel, in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain)
                }
            }
            Button("■ Stop Sound") { audio.stop() }.buttonStyle(.bordered)
            Spacer()
            PrimaryAction(title: "Done — Complete Module") { audio.stop(); state.finish(2); DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { dismiss() } }
        }.padding() }.modifier(LessonBackground()).onDisappear { audio.stop() }
    }
}

final class VoiceRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var hasRecording = false
    @Published var message = ""
    private var recorder: AVAudioRecorder?
    private var playback: AVAudioPlayer?
    private var url: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("my-melody.m4a")
    }
    override init() {
        super.init()
        hasRecording = FileManager.default.fileExists(atPath: url.path)
    }
    func toggle() {
        if isRecording { recorder?.stop(); isRecording = false; hasRecording = true; message = "Melody saved on this device."; return }
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                guard granted else { self.message = "Enable microphone permission in Settings."; return }
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                    try AVAudioSession.sharedInstance().setActive(true)
                    self.recorder = try AVAudioRecorder(url: self.url, settings: [
                        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 44100,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ])
                    self.recorder?.record(); self.isRecording = true
                    self.message = "Recording… hum your melody."
                } catch { self.message = "Recording error: \(error.localizedDescription)" }
            }
        }
    }
    func play() {
        do { playback = try AVAudioPlayer(contentsOf: url); playback?.play() }
        catch { message = "Playback error: \(error.localizedDescription)" }
    }
}

struct MelodyView: View {
    @EnvironmentObject var state: StudioState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = VoiceRecorder()
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("FIND YOUR MELODY").font(.title2.bold())
                Vinyl(color: .mint, size: 145)
                LessonCard(title: "Start with a feeling", description: "Choose a mood: joyful, nostalgic, confident, calm, or something entirely your own. Let that emotion guide your notes.")
                LessonCard(title: "Hum before you judge", description: "Play with short musical phrases. Repeat a memorable idea, then vary the ending to keep it interesting.")
                LessonCard(title: "Leave room to breathe", description: "Mix longer and shorter notes. Silence and repetition can be as powerful as complexity.")
                LessonCard(title: "Capture the spark", description: "When a tune comes to mind, hum it and record it. Listen back and refine what you like.")
                Button {
                    recorder.toggle()
                } label: {
                    Label(recorder.isRecording ? "Stop Recording" : "Record Your Hum", systemImage: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .frame(maxWidth: .infinity).padding(15)
                        .background(recorder.isRecording ? Color.red : Color.mint, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(Palette.background)
                }
                if recorder.hasRecording {
                    Button("▶ Play My Recording") { recorder.play() }.buttonStyle(.bordered)
                }
                if !recorder.message.isEmpty { Text(recorder.message).font(.caption).foregroundStyle(.gray) }
                PrimaryAction(title: "Done — Complete Module") { if recorder.isRecording { recorder.toggle() }; state.finish(3); DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { dismiss() } }
            }.padding()
        }.modifier(LessonBackground()).navigationTitle("Module 4")
    }
}

struct SandboxView: View {
    @EnvironmentObject var state: StudioState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audio = MusicEngine()
    @State private var songName = "My First Song"
    @State private var chosenProgression = 0
    @State private var chosenBeat = 0
    @State private var saved = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("GOLDEN SANDBOX").font(.title.bold()).foregroundStyle(Palette.gold)
                Text("Build your first musical idea with chords and rhythm.").foregroundStyle(.gray)
                TextField("Song title", text: $songName).textFieldStyle(.roundedBorder).foregroundStyle(.black)
                Text("1. CHOOSE YOUR CHORDS").font(.headline)
                Picker("Chord Progression", selection: $chosenProgression) {
                    ForEach(progressions) { Text("\( $0.name ): \($0.chords.joined(separator: "–"))").tag($0.id) }
                }.tint(Palette.gold)
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { i in
                        Button(progressions[chosenProgression].chords[i]) {
                            audio.playChord(progressions[chosenProgression].notes[i])
                        }.frame(maxWidth: .infinity).padding(.vertical, 18)
                            .background(.white, in: RoundedRectangle(cornerRadius: 10)).foregroundStyle(.black)
                    }
                }
                Button("▶ Play Chord Loop") {
                    audio.stop()
                    for chord in progressions[chosenProgression].notes { audio.playChord(chord, duration: 0.65) }
                }.buttonStyle(.bordered)
                Divider()
                Text("2. CHOOSE YOUR DRUM BEAT").font(.headline)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(beats) { beat in
                        Button(beat.name) {
                            chosenBeat = beat.id
                            audio.stop(); audio.playBeat(beat.steps)
                        }.frame(maxWidth: .infinity).padding(15)
                            .background(chosenBeat == beat.id ? Palette.gold.opacity(0.45) : Palette.panel, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                Button("▶ Play Beat") { audio.stop(); audio.playBeat(beats[chosenBeat].steps) }.buttonStyle(.bordered)
                Button("■ Stop") { audio.stop() }.buttonStyle(.bordered)
                Divider()
                Text("3. SAVE YOUR SONG IDEA").font(.headline)
                Text("Your chord progression and drum choice will be saved on this device. You can add your recorded melody from Module 4 separately.")
                    .font(.subheadline).foregroundStyle(.gray)
                PrimaryAction(title: "Save Song Idea") {
                    let idea = SongIdea(title: songName, progression: chosenProgression, beat: chosenBeat, createdAt: Date())
                    SongLibrary.save(idea)
                    state.finish(4)
                    saved = true
                }
                if saved {
                    Label("Saved to your song library!", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    PrimaryAction(title: "▶ Play Your Song") {
                        audio.playSong(progression: progressions[chosenProgression], beat: beats[chosenBeat])
                    }
                }
                NavigationLink("View Saved Songs", destination: SongLibraryView())
                    .frame(maxWidth: .infinity).padding(15).background(Palette.panel, in: RoundedRectangle(cornerRadius: 14))
            }.padding()
        }.modifier(LessonBackground()).navigationTitle("Sandbox")
            .onAppear { chosenProgression = state.selectedProgression; chosenBeat = state.selectedBeat }
            .onDisappear { audio.stop() }
    }
}

struct SongIdea: Codable, Identifiable {
    var id = UUID()
    let title: String
    let progression: Int
    let beat: Int
    let createdAt: Date
}

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

struct SongLibraryView: View {
    @StateObject private var audio = MusicEngine()
    @State private var songs = SongLibrary.load()
    var body: some View {
        List {
            if songs.isEmpty { Text("No song ideas saved yet.") }
            ForEach(songs) { song in
                VStack(alignment: .leading, spacing: 6) {
                    Text(song.title).font(.headline)
                    Text("\(progressions[song.progression].chords.joined(separator: " – ")) · \(beats[song.beat].name) beat")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(song.createdAt, style: .date).font(.caption2).foregroundStyle(.secondary)
                    Button("▶ Play song") {
                        guard progressions.indices.contains(song.progression), beats.indices.contains(song.beat) else { return }
                        audio.playSong(progression: progressions[song.progression], beat: beats[song.beat])
                    }.buttonStyle(.bordered)
                }
            }
            .onDelete { offsets in
                songs.remove(atOffsets: offsets)
                if let data = try? JSONEncoder().encode(songs) { UserDefaults.standard.set(data, forKey: SongLibrary.key) }
            }
        }.navigationTitle("My Songs").onDisappear { audio.stop() }
    }
}
