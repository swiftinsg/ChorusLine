import SwiftUI
import UIKit

/// One card of lesson content shown in a `LessonSlideshow`.
struct LessonSlide {
    let title: String
    let description: String
}

/// A swipe-driven deck of lesson cards presented above a large half-visible
/// record. Swiping across the record spins it and turns the page, and swiping
/// past the last card calls `onFinish`.
struct LessonSlideshow: View {
    let moduleTitle: String
    let accent: Color
    let slides: [LessonSlide]
    var showsSwipeHint = false
    let onFinish: () -> Void

    @State private var page = 0
    @State private var spin = 0.0
    @State private var drag: CGFloat = 0
    @State private var isDragging = false
    @State private var crossedThreshold = false
    @State private var movingForward = true
    @State private var introScale = 0.6

    private let threshold: CGFloat = 64

    var body: some View {
        GeometryReader { proxy in
            deck(height: proxy.size.height)
        }
        .modifier(LessonBackground())
        .navigationTitle("")
    }

    /// The record is sized to two-thirds of the available height and pushed
    /// half-way below the bottom edge, so its visible half fills the bottom
    /// third of the screen.
    private func deck(height: CGFloat) -> some View {
        let vinylSize = height * 2 / 3
        let hint = page == slides.count - 1
            ? "Swipe the record to continue"
            : "Swipe the record to spin to the next part"

        return VStack(spacing: 16) {
            Text(moduleTitle)
                .font(.system(size: 28, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(Palette.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 8)
            ProgressView(value: Double(page + 1), total: Double(slides.count))
                .tint(accent)
                .accessibilityLabel("Lesson progress")
            ScrollView {
                ZStack {
                    LessonCard(title: slides[page].title, description: slides[page].description)
                        .id(page)
                        .transition(pageTransition)
                }
            }
            Spacer(minLength: 0)
            if showsSwipeHint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, vinylSize / 2 + 12)
            } else {
                Color.clear.frame(height: vinylSize / 2 + 12)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            Vinyl(color: accent, size: vinylSize)
                .rotationEffect(.degrees(spin + Double(drag) * 0.55))
                .scaleEffect(introScale * (isDragging ? 1.03 : 1))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
                .offset(y: vinylSize / 2)
                .contentShape(Circle())
                .gesture(swipeGesture)
                .accessibilityLabel("Half vinyl record. Swipe to change part")
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.68)) { introScale = 1 }
        }
    }

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: CardTurn(angle: movingForward ? -75 : 75, opacity: 0),
                identity: CardTurn(angle: 0, opacity: 1)
            ),
            removal: .modifier(
                active: CardTurn(angle: movingForward ? 75 : -75, opacity: 0),
                identity: CardTurn(angle: 0, opacity: 1)
            )
        )
    }

    /// Tracks the finger so the record rotates as you drag, then commits or
    /// springs back based on the distance and flick speed.
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                isDragging = true
                drag = value.translation.width
                if abs(drag) > threshold && !crossedThreshold {
                    crossedThreshold = true
                    UISelectionFeedbackGenerator().selectionChanged()
                } else if abs(drag) <= threshold && crossedThreshold {
                    crossedThreshold = false
                }
            }
            .onEnded { value in
                let flick = value.predictedEndTranslation.width
                let translation = abs(flick) > abs(value.translation.width) ? flick : value.translation.width
                let commit = abs(translation) > threshold
                let direction = translation < 0 ? 1 : -1
                let dragSpin = Double(drag) * 0.55

                isDragging = false
                crossedThreshold = false

                if commit {
                    spinToPage(page + direction, carrying: dragSpin)
                } else {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                        drag = 0
                    }
                }
            }
    }

    private func spinToPage(_ target: Int, carrying dragSpin: Double) {
        movingForward = target >= page
        withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
            spin += dragSpin + (movingForward ? 360 : -360)
            drag = 0
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        guard target >= 0 else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            if target < slides.count {
                page = target
            } else {
                onFinish()
            }
        }
    }
}

/// Rotates a card away from the viewer, like a page turning over.
private struct CardTurn: ViewModifier {
    let angle: Double
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .opacity(opacity)
    }
}
