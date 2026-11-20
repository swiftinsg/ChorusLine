import SwiftUI
import UIKit

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
            Text(questions[question].0)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            ZStack {
                Vinyl(color: .purple, size: 245, showCenterDot: false, showsRimMark: true)
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
                        .frame(width: 92)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(.white)
                .allowsHitTesting(false)
            }
            .modifier(CircularVinylGesture(diameter: 245) { direction in
                guard !isAdvancing else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { rotation += Double(direction) * 65 }
                selected = (selected + direction + 4) % 4
                UISelectionFeedbackGenerator().selectionChanged()
                revealed = false
                withAnimation(.easeOut(duration: 0.15)) { feedback = "" }
                showCorrect = false
            })

            Text("Move your finger around the edge of the vinyl to choose an answer")
                .font(.caption).foregroundStyle(.gray).multilineTextAlignment(.center)
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
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            withAnimation(.easeOut(duration: 0.2)) {
                feedback = "Not quite — spin and try again."
            }
        }
    }

    /// Shows the success feedback, then moves to the next question on its own.
    private func celebrate() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
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
}
