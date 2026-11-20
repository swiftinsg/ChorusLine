import SwiftUI

/// A record that can spin to show that a module has been completed.
struct Vinyl: View {
    var color: Color = .purple
    var spinning = false
    var size: CGFloat = 132
    var showCenterDot = true
    var showsRimMark = false
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
            if showsRimMark {
                // A short highlight on the outer edge makes the spin easy to see
                // without adding a marker dot.
                Circle().trim(from: 0, to: 0.08)
                    .stroke(Palette.gold.opacity(0.9), style: StrokeStyle(lineWidth: max(5, size * 0.03), lineCap: .round))
                    .padding(size * 0.07)
                    .rotationEffect(.degrees(-90))
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
