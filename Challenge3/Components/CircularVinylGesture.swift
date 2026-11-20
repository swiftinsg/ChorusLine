import SwiftUI

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
