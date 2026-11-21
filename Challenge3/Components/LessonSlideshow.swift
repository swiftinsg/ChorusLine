// Import SwiftUI for the View protocol, state wrappers, gestures, and view modifiers used below.
import SwiftUI
// UIKit is only needed on Apple platforms that provide it, for haptic feedback generators.
#if canImport(UIKit)
// Import UIKit so UISelectionFeedbackGenerator and UIImpactFeedbackGenerator are available.
import UIKit
// End of the UIKit-only import block.
#endif

/// One card of lesson content shown in a `LessonSlideshow`.
// A single lesson card's data: a heading plus the explanatory text shown under it.
struct LessonSlide {
    // The title displayed prominently at the top of the card.
    let title: String
    // The body text explaining the concept on this card.
    let description: String
// End of LessonSlide's stored property declarations.
}

/// A swipe-driven deck of lesson cards presented above a large half-visible
/// record. Swiping across the record spins it and turns the page, and swiping
/// past the last card calls `onFinish`.
// The reusable lesson deck view: content cards animate while a vinyl record below reacts to swipes.
struct LessonSlideshow: View {
    // The module name shown as a header above the progress bar.
    let moduleTitle: String
    // The module's theme color, passed to the vinyl record for its tint.
    let accent: Color
    // The ordered lesson cards; the index into this array is the current page.
    let slides: [LessonSlide]
    // When true, reserve space for a hint telling the learner to swipe the record.
    var showsSwipeHint = false
    // Closure invoked once the learner swipes past the final card, to advance to the interactive module.
    let onFinish: () -> Void

    // The index of the card currently on screen; changing it triggers SwiftUI view updates.
    @State private var page = 0
    // Cumulative rotation in degrees of the record, increased by a full turn on each page change.
    @State private var spin = 0.0
    // Horizontal drag distance in points, used to make the record follow the finger and decide the swipe commit.
    @State private var drag: CGFloat = 0
    // True while a drag gesture is active, used to slightly enlarge the record for touch feedback.
    @State private var isDragging = false
    // Remembers whether the current drag already crossed the threshold, so haptics fire only once per swipe.
    @State private var crossedThreshold = false
    // Records the swipe direction so the outgoing and incoming cards flip the correct way.
    @State private var movingForward = true
    // Starts the record small so it can spring to full size when the view appears.
    @State private var introScale = 0.6

    // The minimum horizontal travel required before a swipe counts as a page turn.
    private let threshold: CGFloat = 64

    // The root view measures its container so the record can be sized relative to the screen height.
    var body: some View {
        // GeometryReader supplies the available height to size the vinyl and the hint spacer.
        GeometryReader { proxy in
            // Build the card/record layout using the measured height.
            deck(height: proxy.size.height)
        }
        // Apply the shared lesson background (colors, texture) behind the whole deck.
        .modifier(LessonBackground())
        // Hide any inherited navigation title because the module title is drawn manually.
        .navigationTitle("")
    }

    /// The record is sized to two-thirds of the available height and pushed
    /// half-way below the bottom edge, so its visible half fills the bottom
    /// third of the screen.
    // Builds the deck: header, progress, swipeable card, and the half-visible spinning record overlay.
    private func deck(height: CGFloat) -> some View {
        // The vinyl's diameter is two-thirds of the screen height; half of it will hang off-screen.
        let vinylSize = height * 2 / 3
        // Choose a context-sensitive hint: the last card tells the learner how to leave the lesson.
        let hint = page == slides.count - 1
            // Final-card wording: swiping continues into the interactive part of the module.
            ? "Swipe the record to continue"
            // Earlier-card wording: swiping spins the record to the next lesson section.
            : "Swipe the record to spin to the next part"

        // Stack the header, progress bar, card area, and bottom spacing vertically.
        return VStack(spacing: 16) {
            // Show the module name as a prominent header.
            Text(moduleTitle)
                // Use a large bold system font so the module reads as a title.
                .font(.system(size: 28, weight: .bold))
                // Add letter spacing for a stylized music-studio look.
                .tracking(1.5)
                // Color the title with the app's accent palette.
                .foregroundStyle(Palette.accent)
                // Keep the title on one line even for longer module names.
                .lineLimit(1)
                // Shrink the font if needed so the title still fits the available width.
                .minimumScaleFactor(0.7)
                // Add a small gap above the title for breathing room.
                .padding(.top, 8)
            // Show progress as a bar filled according to the current card number.
            ProgressView(value: Double(page + 1), total: Double(slides.count))
                // Tint the bar with the module's accent color for visual consistency.
                .tint(accent)
                // Give assistive technologies a meaningful label for the progress indicator.
                .accessibilityLabel("Lesson progress")
            // Make the card area scrollable so long lesson text is never clipped on small screens.
            ScrollView {
                // Layer card views in the same spot so transitions overlap cleanly.
                ZStack {
                    // Render the card for the current page using its title and description.
                    LessonCard(title: slides[page].title, description: slides[page].description)
                        // Give the card a page-based identity so SwiftUI treats each page as a new view and animates its transition.
                        .id(page)
                        // Apply the direction-aware card flip when a page appears or disappears.
                        .transition(pageTransition)
                }
            }
            // Push the card block upward, leaving flexible empty space below it.
            Spacer(minLength: 0)
            // Only show the swipe hint when the caller requests it.
            if showsSwipeHint {
                // Display the instruction chosen above for the current page.
                Text(hint)
                    // Use small caption text so it reads as a helper, not main content.
                    .font(.caption)
                    // Mute the color so the hint stays visually secondary.
                    .foregroundStyle(Palette.muted)
                    // Allow the hint to wrap across multiple lines if needed.
                    .multilineTextAlignment(.center)
                    // Reserve enough bottom space so the hint sits above the visible half of the record.
                    .padding(.bottom, vinylSize / 2 + 12)
            } else {
                // Keep the same spacing even without a hint, so card positions don't jump between modules.
                Color.clear.frame(height: vinylSize / 2 + 12)
            }
        }
        // Add side margins so the card and header don't touch the screen edges.
        .padding(.horizontal, 20)
        // Let the stack fill all available space so the bottom-aligned overlay has a stable anchor.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Place the vinyl at the bottom center, overlapping the lower part of the stack.
        .overlay(alignment: .bottom) {
            // Draw the record with the module accent color at the calculated size.
            Vinyl(color: accent, size: vinylSize)
                // Combine the accumulated spin with the live drag rotation so the record turns under the finger.
                .rotationEffect(.degrees(spin + Double(drag) * 0.55))
                // Slightly enlarge the record while dragging to signal that it is interactive.
                .scaleEffect(introScale * (isDragging ? 1.03 : 1))
                // Animate the press/unpress scale with a spring for a tactile feel.
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
                // Shift the record down by half its height so only its top half is visible.
                .offset(y: vinylSize / 2)
                // Make the whole circular area tappable/draggable, not just the drawn pixels.
                .contentShape(Circle())
                // Attach the swipe gesture that turns pages and spins the record.
                .gesture(swipeGesture)
                // Describe the control for VoiceOver users.
                .accessibilityLabel("Half vinyl record. Swipe to change part")
        }
        // Animate the record growing from its initial small scale when the view first appears.
        .onAppear {
            // Spring the intro scale to full size for a playful entrance animation.
            withAnimation(.spring(response: 0.7, dampingFraction: 0.68)) { introScale = 1 }
        }
    }

    // Builds the asymmetric flip transition: new cards enter from the opposite side the old ones leave.
    private var pageTransition: AnyTransition {
        // Use different animations for insertion and removal based on swipe direction.
        .asymmetric(
            // The incoming card starts tilted away and transparent, then settles flat and opaque.
            insertion: .modifier(
                // Negative angle when moving forward, positive when moving backward.
                active: CardTurn(angle: movingForward ? -75 : 75, opacity: 0),
                // Fully visible, untilted end state of the incoming card.
                identity: CardTurn(angle: 0, opacity: 1)
            ),
            // The outgoing card tilts away in the opposite direction and fades out.
            removal: .modifier(
                // Positive angle when moving forward, negative when moving backward.
                active: CardTurn(angle: movingForward ? 75 : -75, opacity: 0),
                // Fully visible, untilted start state of the outgoing card.
                identity: CardTurn(angle: 0, opacity: 1)
            )
        )
    }

    /// Tracks the finger so the record rotates as you drag, then commits or
    /// springs back based on the distance and flick speed.
    // Defines the drag interaction: follow the finger, give haptic feedback at the threshold, and commit on release.
    private var swipeGesture: some Gesture {
        // Ignore tiny movements; begin tracking once the finger moves at least 8 points.
        DragGesture(minimumDistance: 8)
            // Update the record continuously while the finger moves.
            .onChanged { value in
                // Mark the interaction as active so the record can scale up slightly.
                isDragging = true
                // Store horizontal travel so the record rotates in sync with the finger.
                drag = value.translation.width
                // Fire a selection haptic the first time the swipe passes the commit threshold.
                if abs(drag) > threshold && !crossedThreshold {
                    // Remember that the haptic already fired for this swipe.
                    crossedThreshold = true
                    // Compile haptic feedback only on iOS where UIKit is available.
                    #if os(iOS)
                    // Provide a subtle click so the learner feels the page-turn threshold.
                    UISelectionFeedbackGenerator().selectionChanged()
                    // End of the iOS-only selection haptic block.
                    #endif
                // Reset the flag if the finger returns inside the threshold, allowing a new haptic if it crosses again.
                } else if abs(drag) <= threshold && crossedThreshold {
                    // Clear the flag so crossing the threshold again can trigger feedback.
                    crossedThreshold = false
                }
            }
            // Decide whether to turn the page or snap the record back when the finger lifts.
            .onEnded { value in
                // Use the predicted end position to recognize quick flicks as deliberate swipes.
                let flick = value.predictedEndTranslation.width
                // Prefer the stronger signal: the predicted flick distance or the actual drag distance.
                let translation = abs(flick) > abs(value.translation.width) ? flick : value.translation.width
                // Commit the page turn only if the chosen distance passes the threshold.
                let commit = abs(translation) > threshold
                // A left swipe moves forward; a right swipe moves backward.
                let direction = translation < 0 ? 1 : -1
                // Capture the spin accumulated during the drag so the page-turn animation continues smoothly.
                let dragSpin = Double(drag) * 0.55

                // End the press state so the record returns to its normal scale.
                isDragging = false
                // Clear the one-shot haptic flag for the next gesture.
                crossedThreshold = false

                // Turn the page only when the swipe qualified as a commit.
                if commit {
                    // Animate to the neighboring page and carry the drag rotation into the spin.
                    spinToPage(page + direction, carrying: dragSpin)
                } else {
                    // Spring the drag offset back to zero so the record returns to its resting position.
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                        // Reset the live drag translation after a cancelled swipe.
                        drag = 0
                    }
                }
            }
    }

    // Spins the record a full turn and updates the page, or finishes the lesson past the last card.
    private func spinToPage(_ target: Int, carrying dragSpin: Double) {
        // Remember direction so the card transition flips the correct way.
        movingForward = target >= page
        // Animate the record spinning a full revolution plus the carried drag rotation.
        withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
            // Add 360 degrees forward or backward, continuing from the in-progress drag rotation.
            spin += dragSpin + (movingForward ? 360 : -360)
            // Clear the live drag offset now that the full spin animation owns the rotation.
            drag = 0
        }
        // Compile impact feedback only on iOS where UIKit is available.
        #if os(iOS)
        // Give a light thump to confirm the page turn actually happened.
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        // End of the iOS-only impact haptic block.
        #endif

        // Ignore swipe attempts before the first card; there is nothing to go back to.
        guard target >= 0 else { return }
        // Animate the card content change to match the spinning record.
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            // Move to the next/previous card when the target is still within the slides array.
            if target < slides.count {
                // Update the current page index, which swaps the visible lesson card.
                page = target
            } else {
                // Past the final card: notify the parent so it can open the interactive module.
                onFinish()
            }
        }
    }
}

/// Rotates a card away from the viewer, like a page turning over.
// A reusable modifier used by the page transition to tilt and fade a lesson card in 3D.
private struct CardTurn: ViewModifier {
    // Rotation in degrees around the vertical axis; sign decides which way the card flips.
    let angle: Double
    // Opacity at this stage of the transition (0 during flight, 1 at rest).
    let opacity: Double

    // Applies the 3D rotation and transparency to whatever card view is being transitioned.
    func body(content: Content) -> some View {
        // Start from the original card content supplied by SwiftUI.
        content
            // Rotate around the vertical (y) axis with perspective for a page-turn illusion.
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            // Fade the card in or out alongside the rotation.
            .opacity(opacity)
    }
}
