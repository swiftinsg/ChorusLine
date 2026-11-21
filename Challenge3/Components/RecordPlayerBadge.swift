import SwiftUI

/// A top-down miniature turntable used to mark a completed module on the menu.
/// The record "drops" onto the platter on appear to mirror the completion animation.
struct RecordPlayerBadge: View {
    let color: Color
    var size: CGFloat = 100
    var accent: Color = Palette.accent
    @State private var dropped = false

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color(white: 0.32), Palette.panel, Color(white: 0.07)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    Circle().stroke(accent.opacity(0.35), lineWidth: max(1, size * 0.012))
                }
                .shadow(color: .black.opacity(0.6), radius: size * 0.06, y: size * 0.04)

            Vinyl(color: color, spinning: true, size: size * 0.82, showCenterDot: true, showsGlow: false)
                .scaleEffect(dropped ? 1 : 0.55)
                .offset(y: dropped ? 0 : -size * 0.16)

            tonearm
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) { dropped = true }
        }
    }

    private var tonearm: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: size * 0.85, y: size * 0.14))
                path.addLine(to: CGPoint(x: size * 0.75, y: size * 0.30))
                path.addLine(to: CGPoint(x: size * 0.68, y: size * 0.52))
            }
            .stroke(accent, style: StrokeStyle(lineWidth: max(2, size * 0.028), lineCap: .round, lineJoin: .round))

            Circle()
                .fill(Color(white: 0.2))
                .frame(width: size * 0.14, height: size * 0.14)
                .overlay {
                    Circle().stroke(accent.opacity(0.5), lineWidth: max(1, size * 0.012))
                }
                .position(x: size * 0.85, y: size * 0.14)

            Circle()
                .fill(Color.white)
                .frame(width: max(5, size * 0.06), height: max(5, size * 0.06))
                .position(x: size * 0.85, y: size * 0.14)
        }
    }
}
