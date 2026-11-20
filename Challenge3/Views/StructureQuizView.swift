import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Quiz shown at the end of Module 1.
struct StructureQuiz: View {
    @EnvironmentObject var state: StudioState
    @Environment(\.dismiss) private var dismiss
    @State private var question = 0
    @State private var selected = 0
    @State private var rotation = 0.0
    @State private var revealed = false
    @State private var feedback = ""
    @State private var recordPulse = false
    @State private var showCorrect = false
    @State private var isAdvancing = false
    @State private var flyingNotes: [NoteParticle] = []
    private let questions: [(String, [String], Int)] = [
        ("Which section usually contains the main repeated hook?", ["Verse", "Chorus", "Bridge", "Outro"], 1),
        ("What does a pre-chorus typically do?", ["End the song", "Introduce credits", "Build into the chorus", "Replace the beat"], 2),
        ("Which section often offers a musical contrast?", ["Bridge", "Verse 2", "Intro", "Outro"], 0)
    ]
    var body: some View {
        VStack(spacing: 22) {
            Text("SPIN THE ANSWERS").font(.title2.bold())
            ProgressView(value: Double(question + 1), total: Double(questions.count))
                .tint(Palette.accent).accessibilityLabel("Quiz progress")
            Text(questions[question].0)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            GeometryReader { geo in
                let vinylSize = min(260, max(180, geo.size.width - 20))
                ZStack {
                    Vinyl(color: Palette.accent, size: vinylSize, showCenterDot: false, showsRimMark: true)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(recordPulse ? 1.06 : 1)
                        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: recordPulse)
                        .shadow(color: showCorrect ? Color.green.opacity(0.75) : .clear, radius: 28)

                    // Keep the answer inside the record's centre label so it never
                    // bleeds out over the grooves.
                    VStack(spacing: 4) {
                        Text("ANSWER").font(.caption2.bold()).tracking(2)
                        Text(questions[question].1[selected])
                            .font(.system(size: 15, weight: .bold))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                            .frame(width: max(70, vinylSize * 0.37))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(.white)
                    .allowsHitTesting(false)

                    ForEach(flyingNotes) { note in
                        FlyingMusicNote(particle: note)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .modifier(CircularVinylGesture(diameter: vinylSize) { direction in
                guard !isAdvancing else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { rotation += Double(direction) * 65 }
                selected = (selected + direction + 4) % 4
                spawnFlyingNotes()
                #if os(iOS)
                UISelectionFeedbackGenerator().selectionChanged()
                #endif
                revealed = false
                withAnimation(.easeOut(duration: 0.15)) { feedback = "" }
                showCorrect = false
            })
            }
            .frame(height: 280)

            Text("Move your finger around the edge of the vinyl to choose an answer")
                .font(.caption).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
            if !feedback.isEmpty {
                Text(feedback)
                    .foregroundStyle(feedback == "Correct!" ? .green : .orange)
                    .font(showCorrect ? .headline.bold() : .body)
                    .transition(.scale.combined(with: .opacity))
            }
            Spacer()
            PrimaryAction(title: "Check Answer") { checkAnswer() }
                .disabled(isAdvancing || (revealed && selected == questions[question].2))
        }
        .padding()
        .modifier(LessonBackground())
        .navigationTitle("")
    }

    private func checkAnswer() {
        guard !isAdvancing else { return }
        revealed = true

        if selected == questions[question].2 {
            celebrate()
        } else {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            #endif
            withAnimation(.easeOut(duration: 0.2)) {
                feedback = "Not quite — spin and try again."
            }
        }
    }

    /// Shows the success feedback, then moves to the next question on its own.
    private func celebrate() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        recordPulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { recordPulse = false }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
            feedback = "Correct!"
            showCorrect = true
        }

        isAdvancing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            if question == questions.count - 1 {
                state.finish(0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { dismiss() }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    question += 1
                    revealed = false
                    feedback = ""
                    selected = 0
                    showCorrect = false
                }
                isAdvancing = false
            }
        }
    }

    /// Spawns music notes that fly outward as the vinyl is spun.
    private func spawnFlyingNotes() {
        let count = Int.random(in: 2...4)
        for _ in 0..<count {
            let particle = NoteParticle(
                angle: Double.random(in: 0...(2 * .pi)),
                startRadius: CGFloat.random(in: 88...118),
                distance: CGFloat.random(in: 90...170),
                size: CGFloat.random(in: 26...36),
                spin: Double.random(in: -70...70),
                symbol: "music.note"
            )
            flyingNotes.append(particle)
            let id = particle.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                flyingNotes.removeAll { $0.id == id }
            }
        }
    }
}

private struct NoteParticle: Identifiable {
    let id = UUID()
    let angle: Double
    let startRadius: CGFloat
    let distance: CGFloat
    let size: CGFloat
    let spin: Double
    let symbol: String
}

private struct FlyingMusicNote: View {
    let particle: NoteParticle
    @State private var travel = false

    var body: some View {
        Image(systemName: particle.symbol)
            .font(.system(size: particle.size, weight: .black))
            .foregroundStyle(.white)
            .shadow(color: Palette.accent, radius: 8)
            .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
            .offset(
                x: cos(particle.angle) * (particle.startRadius + (travel ? particle.distance : 0)),
                y: sin(particle.angle) * (particle.startRadius + (travel ? particle.distance : 0)) - (travel ? 18 : 0)
            )
            .opacity(travel ? 0 : 1)
            .scaleEffect(travel ? 1.25 : 0.75)
            .rotationEffect(.degrees(travel ? particle.spin : 0))
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    travel = true
                }
            }
            .allowsHitTesting(false)
    }
}
