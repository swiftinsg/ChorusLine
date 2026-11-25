// -----------------------------------------------------------------------------
// FILE SUMMARY — Views/StructureQuizView.swift
// -----------------------------------------------------------------------------
// PURPOSE: Module 1 quiz with three multiple-choice questions answered by
//          spinning a vinyl; correct answers celebrate and auto-advance.
//
// TYPES / FUNCTIONS:
//   • body — progress bar, question prompt, large vinyl with answer label and
//     flying notes, hint, feedback banner and Check Answer button. Uses
//     CircularVinylGesture to rotate the record and cycle the four answers.
//   • checkAnswer() — compares the selection with the correct index, celebrating
//     or showing a retry message, both with haptic feedback.
//   • celebrate() — success haptics, record pulse, green feedback, then advances
//     to the next question or completes module 0 and dismisses.
//   • spawnFlyingNotes() — creates 2–4 random NoteParticle values and removes
//     each after its one-second flight.
//   • NoteParticle — data for one note glyph (angle, radii, size, spin, symbol).
//   • FlyingMusicNote — view that animates a particle outward and fades it out.
// -----------------------------------------------------------------------------

// Import SwiftUI for the view hierarchy, animations, gestures, and state wrappers.
import SwiftUI
// Compile the following import and haptic code only when UIKit is available.
#if canImport(UIKit)
// Import UIKit so the quiz can fire iOS haptic feedback generators.
import UIKit
// End of the UIKit-only import block.
#endif

/// Quiz shown at the end of Module 1.
// Define the Module 1 quiz that asks users to identify song sections by spinning a vinyl.
struct StructureQuiz: View {
    // Receive the shared studio state from the environment so the quiz can mark Module 1 complete.
    @EnvironmentObject var state: StudioState
    // Read the SwiftUI dismiss action so the quiz can close itself when finished.
    @Environment(\.dismiss) private var dismiss
    // @State tracks the current question index and triggers UI updates when it changes.
    @State private var question = 0
    // @State holds the index of the currently highlighted answer choice.
    @State private var selected = 0
    // @State stores the vinyl's rotation in degrees so spinning feels continuous between gestures.
    @State private var rotation = 0.0
    // @State records whether the answer has been checked for the current question.
    @State private var revealed = false
    // @State holds the feedback message shown below the vinyl.
    @State private var feedback = ""
    // @State toggles the record's celebratory scale pulse after a correct answer.
    @State private var recordPulse = false
    // @State switches the feedback styling and green glow to the success state.
    @State private var showCorrect = false
    // @State locks interaction while the quiz transitions between questions.
    @State private var isAdvancing = false
    // @State stores the active note particles so SwiftUI can render and animate each one.
    @State private var flyingNotes: [NoteParticle] = []
    // Store each question as a prompt, four answer choices, and the index of the correct choice.
    private let questions: [(String, [String], Int)] = [
        // Define question 1; index 1 means "Chorus" is the correct answer.
        ("Which section usually contains the main repeated hook?", ["Verse", "Chorus", "Bridge", "Outro"], 1),
        // Define question 2; index 2 marks the build into the chorus as correct.
        ("What does a pre-chorus typically do?", ["End the song", "Introduce credits", "Build into the chorus", "Replace the beat"], 2),
        // Define question 3; index 0 marks "Bridge" as correct.
        ("Which section often offers a musical contrast?", ["Bridge", "Verse 2", "Intro", "Outro"], 0)
    ]
    // Assemble the quiz layout from progress, prompt, spinning vinyl, feedback, and action button.
    var body: some View {
        // Arrange the quiz elements vertically with generous spacing between sections.
        VStack(spacing: 22) {
            // Display the instruction title so the interaction is immediately clear.
            Text("SPIN THE ANSWERS").font(.title2.bold())
            // Show how many questions are complete out of the total, converting Ints to Doubles for the progress bar.
            ProgressView(value: Double(question + 1), total: Double(questions.count))
                // Color the progress bar with the module accent and give screen readers a meaningful label.
                .tint(Palette.structure).accessibilityLabel("Quiz progress")
            // Show the prompt for the current question from the questions array.
            Text(questions[question].0)
                // Make the question prominent so it is the focus of the screen.
                .font(.title3.bold())
                // Center multi-line questions for balanced reading.
                .multilineTextAlignment(.center)
                // Let the text wrap vertically instead of being truncated when the prompt is long.
                .fixedSize(horizontal: false, vertical: true)

            // Read the available width so the vinyl and its touch target scale to the device.
            GeometryReader { geo in
                // Clamp the record diameter between 180 and 260 points with a 20-point margin.
                let vinylSize = min(260, max(180, geo.size.width - 20))
                // Make the spin gesture area at least 80 points larger than the vinyl, capped at 280 and the screen width.
                let hitSize = min(geo.size.width, 280, vinylSize + 80)
                // Overlay the answer label and flying notes on top of the vinyl record.
                ZStack {
                    // Draw the record with a visible rim so users know where to trace their finger.
                    Vinyl(color: Palette.structure, size: vinylSize, showCenterDot: false, showsRimMark: true)
                        // Rotate the record by the accumulated spin angle from the gesture handler.
                        .rotationEffect(.degrees(rotation))
                        // Briefly enlarge the record when a correct answer is celebrated.
                        .scaleEffect(recordPulse ? 1.06 : 1)
                        // Animate the pulse with a spring so it feels like a physical bounce.
                        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: recordPulse)
                        // Add a green glow after a correct answer and keep it clear otherwise.
                        .shadow(color: showCorrect ? Color.green.opacity(0.75) : .clear, radius: 28)

                    // Keep the answer inside the record's centre label so it never
                    // bleeds out over the grooves.
                    // Stack the "ANSWER" caption and selected choice inside the record's center label.
                    VStack(spacing: 4) {
                        // Label the selected choice with small, widely tracked text.
                        Text("ANSWER").font(.caption2.bold()).tracking(2)
                        // Display the currently selected answer for the current question.
                        Text(questions[question].1[selected])
                            // Use bold 15-point type so the answer is readable over the record.
                            .font(.system(size: 15, weight: .bold))
                            // Center the answer text within the label area.
                            .multilineTextAlignment(.center)
                            // Cap the answer at two lines so it stays inside the center label.
                            .lineLimit(2)
                            // Allow slight text shrinking if a long answer would not fit.
                            .minimumScaleFactor(0.75)
                            // Constrain the label to a slice of the record's diameter with a 70-point minimum.
                            .frame(width: max(70, vinylSize * 0.37))
                            // Let the answer grow vertically as needed rather than clip.
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    // Paint the label text white for contrast against the dark vinyl.
                    .foregroundStyle(.white)
                    // Let touches pass through the label to the vinyl spin gesture underneath.
                    .allowsHitTesting(false)

                    // Render one animated note view for each active particle.
                    ForEach(flyingNotes) { note in
                        // Create the note view, which animates its own outward flight on appear.
                        FlyingMusicNote(particle: note)
                    }
                }
                // Size the interactive area to the computed touch target.
                .frame(width: hitSize, height: hitSize)
                // Attach the circular drag gesture that turns finger movement into ±1 spin steps.
                .modifier(CircularVinylGesture(diameter: hitSize) { direction in
                    // Ignore spins while the quiz is advancing to the next question.
                    guard !isAdvancing else { return }
                    // Rotate the record 65 degrees per step with a springy response so the spin feels tactile.
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { rotation += Double(direction) * 65 }
                    // Move the selected answer by one slot with wraparound, adding 4 to keep the modulo positive.
                    selected = (selected + direction + 4) % 4
                    // Emit music notes that fly outward from the spin.
                    spawnFlyingNotes()
                    // Provide haptic feedback only on iOS.
                    #if os(iOS)
                    // Fire a selection tick so each answer change can be felt.
                    UISelectionFeedbackGenerator().selectionChanged()
                    // End of the iOS-only haptic block.
                    #endif
                    // Reset the revealed flag because the user changed the answer after checking.
                    revealed = false
                    // Clear any previous feedback with a quick fade so stale messages do not linger.
                    withAnimation(.easeOut(duration: 0.15)) { feedback = "" }
                    // Remove the success glow and bold feedback styling when the answer changes.
                    showCorrect = false
                })
                // Let the gesture area expand into the GeometryReader so the full region is tappable.
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            // Reserve a fixed height for the vinyl section so the rest of the quiz has a stable layout.
            .frame(height: 280)

            // Explain the unusual circular gesture to first-time users.
            Text("Move your finger around the edge of the vinyl to choose an answer")
                // Style the hint as small, dim, centered text.
                .font(.caption).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
            // Show the feedback banner only after the user has checked an answer.
            if !feedback.isEmpty {
                // Display the correct or try-again message.
                Text(feedback)
                    // Color success green and mistakes orange for instant visual meaning.
                    .foregroundStyle(feedback == "Correct!" ? .green : .orange)
                    // Emphasize the success message with a bold headline font.
                    .font(showCorrect ? .headline.bold() : .body)
                    // Animate the message in with scale and fade so it draws attention.
                    .transition(.scale.combined(with: .opacity))
            }
            // Push the check button toward the bottom of the screen.
            Spacer()
            // Show the main action that validates the selected answer.
            PrimaryAction(title: "Check Answer") { checkAnswer() }
                // Disable the button during transitions and after a correct answer to prevent duplicate submissions.
                .disabled(isAdvancing || (revealed && selected == questions[question].2))
        }
        // Add standard padding around the quiz content.
        .padding()
        // Apply the shared themed background used by other lesson screens.
        .modifier(LessonBackground())
        // Hide the navigation title because the quiz draws its own heading.
        .navigationTitle("")
    }

    // Compare the selected answer with the correct index and route to success or retry feedback.
    private func checkAnswer() {
        // Prevent a second check while the quiz is already moving to another question.
        guard !isAdvancing else { return }
        // Mark the current answer as revealed so the button can be disabled after success.
        revealed = true

        // Check whether the selected choice matches the correct-answer index for this question.
        if selected == questions[question].2 {
            // Run the success animation and schedule the next question on a correct answer.
            celebrate()
        } else {
            // Limit the haptic to iOS devices.
            #if os(iOS)
            // Fire a rigid impact to signal that the answer was wrong.
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            // End of the iOS-only haptic block.
            #endif
            // Animate the feedback text change so it appears smoothly.
            withAnimation(.easeOut(duration: 0.2)) {
                // Tell the user to spin the vinyl and choose another answer.
                feedback = "Not quite, spin and try again."
            }
        }
    }

    /// Shows the success feedback, then moves to the next question on its own.
    // Play the success feedback, then advance automatically after a short pause.
    private func celebrate() {
        // Keep notification haptics on iOS only.
        #if os(iOS)
        // Fire a success notification haptic to celebrate the correct answer.
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        // End of the iOS-only haptic block.
        #endif
        // Start the record's celebratory scale pulse.
        recordPulse = true
        // End the pulse after a brief moment so the record settles back to normal size.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { recordPulse = false }
        // Animate the success feedback with a spring for a lively feel.
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
            // Show the positive confirmation message.
            feedback = "Correct!"
            // Enable the bold feedback style and green vinyl glow.
            showCorrect = true
        }

        // Lock the UI so users cannot spin or check again while the quiz transitions.
        isAdvancing = true
        // Wait long enough for the celebration to be seen before moving on.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            // Determine whether this was the final question in the array.
            if question == questions.count - 1 {
                // Mark Module 0 (song structure) complete in the shared studio state so HomeView can show its badge.
                state.finish(0)
                // Let the completion celebration play, then close the quiz automatically.
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { dismiss() }
            } else {
                // Animate the reset of quiz state for the next question.
                withAnimation(.easeInOut(duration: 0.3)) {
                    // Advance the question index to the next prompt.
                    question += 1
                    // Clear the revealed flag so the next answer can be checked.
                    revealed = false
                    // Remove the previous feedback message from the screen.
                    feedback = ""
                    // Reset the highlighted answer back to the first option.
                    selected = 0
                    // Remove the success glow and emphasis styling.
                    showCorrect = false
                }
                // Unlock the UI so the user can spin the vinyl for the new question.
                isAdvancing = false
            }
        }
    }

    /// Spawns music notes that fly outward as the vinyl is spun.
    // Create a small burst of note particles whenever the vinyl is spun.
    private func spawnFlyingNotes() {
        // Pick a random burst size between two and four notes for variety.
        let count = Int.random(in: 2...4)
        // Repeat the particle-creation work once per note in the burst.
        for _ in 0..<count {
            // Build a particle with randomized position, travel distance, size, and rotation.
            let particle = NoteParticle(
                // Choose a random direction around the full circle in radians.
                angle: Double.random(in: 0...(2 * .pi)),
                // Start the note near the record's outer grooves.
                startRadius: CGFloat.random(in: 88...118),
                // Decide how far the note will travel outward from its start radius.
                distance: CGFloat.random(in: 90...170),
                // Vary the glyph size so the burst looks organic.
                size: CGFloat.random(in: 26...36),
                // Give each note a random clockwise or counterclockwise spin in degrees.
                spin: Double.random(in: -70...70),
                // Use the standard music note SF Symbol for the particle.
                symbol: "music.note"
            )
            // Add the new particle to @State so SwiftUI renders it immediately.
            flyingNotes.append(particle)
            // Capture the particle's identifier before the asynchronous removal closure.
            let id = particle.id
            // Schedule cleanup after the note's one-second flight completes.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                // Remove only this particle by id so overlapping bursts do not delete each other.
                flyingNotes.removeAll { $0.id == id }
            }
        }
    }
}

// Define the data for one flying note, with Identifiable so ForEach can track it.
private struct NoteParticle: Identifiable {
    // Give each particle a unique identity for SwiftUI list diffs and targeted removal.
    let id = UUID()
    // Store the flight direction in radians measured around the vinyl's center.
    let angle: Double
    // Store the distance from the center where the note begins its flight.
    let startRadius: CGFloat
    // Store how far beyond the start radius the note will travel.
    let distance: CGFloat
    // Store the rendered symbol size in points.
    let size: CGFloat
    // Store the final rotation in degrees for the note's tumble.
    let spin: Double
    // Store the SF Symbol name so the view can render the glyph.
    let symbol: String
}

// Define a single note glyph that animates outward from the vinyl when it appears.
private struct FlyingMusicNote: View {
    // Receive the particle data that determines this note's motion and appearance.
    let particle: NoteParticle
    // @State flips to true on appear, driving the outward animation.
    @State private var travel = false

    // Build the note view and its animation modifiers.
    var body: some View {
        // Render the SF Symbol specified by the particle.
        Image(systemName: particle.symbol)
            // Scale and embolden the glyph using the particle's random size.
            .font(.system(size: particle.size, weight: .black))
            // Draw the note in white so it stands out against the dark vinyl.
            .foregroundStyle(.white)
            // Add an accent-colored glow so the note feels musical and luminous.
            .shadow(color: Palette.structure, radius: 8)
            // Add a subtle dark drop shadow for depth against lighter backgrounds.
            .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
            // Move the note from its start radius toward the outside of the record as travel becomes true.
            .offset(
                // Use cosine to convert the angle into horizontal travel distance.
                x: cos(particle.angle) * (particle.startRadius + (travel ? particle.distance : 0)),
                // Use sine for vertical travel and lift the note 18 points as it finishes.
                y: sin(particle.angle) * (particle.startRadius + (travel ? particle.distance : 0)) - (travel ? 18 : 0)
            )
            // Fade the note out by the end of its flight so it disappears cleanly.
            .opacity(travel ? 0 : 1)
            // Grow the note from small to full size as it flies outward.
            .scaleEffect(travel ? 1.25 : 0.75)
            // Tumble the note to its random final angle as it travels.
            .rotationEffect(.degrees(travel ? particle.spin : 0))
            // Start the flight animation as soon as the view is inserted into the hierarchy.
            .onAppear {
                // Animate the state flip over one second with an ease-out curve.
                withAnimation(.easeOut(duration: 1.0)) {
                    // Trigger all travel-dependent modifiers to animate to their final values.
                    travel = true
                }
            }
            // Make sure decorative notes never intercept the vinyl spin gesture.
            .allowsHitTesting(false)
    }
}
