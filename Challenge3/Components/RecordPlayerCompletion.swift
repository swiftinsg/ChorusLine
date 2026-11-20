import SwiftUI

// A record drops onto a turntable seen from directly above when a module is finished.
struct RecordPlayerCompletion: View {
    let color: Color
    let stage: Int
    var accent: Color = Palette.accent

    var body: some View {
        GeometryReader { geometry in
            // Scale the turntable so the whole completion scene fits on screen.
            let deckWidth = max(170.0, min(geometry.size.width - 36,
                                              340.0,
                                              (geometry.size.height - 300) / 0.90))
            ZStack {
                Palette.background.opacity(0.97).ignoresSafeArea()
                VStack(spacing: 24) {
                    Text("MODULE COMPLETE!")
                        .font(.title2.bold()).foregroundStyle(accent)

                    ZStack {
                        RoundedRectangle(cornerRadius: deckWidth * 0.08)
                            .fill(LinearGradient(colors: [Color(white: 0.31), Palette.panel, Color(white: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .overlay {
                                RoundedRectangle(cornerRadius: deckWidth * 0.08)
                                    .stroke(accent.opacity(0.55), lineWidth: 2)
                            }
                            .shadow(color: .black.opacity(0.7), radius: 16, y: 10)

                        Circle().fill(Color(white: 0.055))
                            .frame(width: deckWidth * 0.77, height: deckWidth * 0.77)
                            .overlay {
                                Circle().stroke(Color.gray.opacity(0.7), lineWidth: max(3, deckWidth * 0.014))
                            }
                            .offset(x: -deckWidth * 0.035, y: -deckWidth * 0.03)

                        // Viewed from above, the record simply settles down onto
                        // the platter instead of sliding in from the side.
                        Vinyl(color: color, spinning: stage == 2, size: deckWidth * 0.66)
                            .scaleEffect(stage == 0 ? 1.30 : stage == 1 ? 1.08 : 1)
                            .offset(x: -deckWidth * 0.035, y: -deckWidth * 0.03)
                            .shadow(color: .black.opacity(0.65), radius: stage == 2 ? 2 : 26, y: stage == 2 ? 1 : 12)

                        // Tonearm rests over the top-right of the deck.
                        Path { path in
                            path.move(to: CGPoint(x: deckWidth * 0.84, y: deckWidth * 0.17))
                            path.addLine(to: CGPoint(x: deckWidth * 0.73, y: deckWidth * 0.30))
                            path.addLine(to: CGPoint(x: deckWidth * 0.65, y: deckWidth * 0.50))
                        }
                        .stroke(accent, style: StrokeStyle(lineWidth: max(4, deckWidth * 0.02), lineCap: .round, lineJoin: .round))
                        Circle().fill(Palette.cream)
                            .frame(width: max(10, deckWidth * 0.047), height: max(10, deckWidth * 0.047))
                            .position(x: deckWidth * 0.84, y: deckWidth * 0.17)
                    }
                    .frame(width: deckWidth, height: deckWidth)

                    Text(stage == 2 ? "Record loaded. Keep creating!" : "Loading your record…")
                        .foregroundStyle(Palette.cream)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
