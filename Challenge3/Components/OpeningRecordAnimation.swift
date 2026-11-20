import SwiftUI

/// Transition shown while a module is opening.
struct OpeningRecordAnimation: View {
    let color: Color
    let stage: Int
    var accent: Color = Palette.accent
    var body: some View {
        ZStack {
            Palette.background.opacity(0.97).ignoresSafeArea()
            VStack(spacing: 26) {
                Text("NOW LOADING").font(.headline).tracking(4).foregroundStyle(accent)
                Vinyl(color: color, spinning: true, size: 220)
                    .scaleEffect(stage == 0 ? 0.48 : 1.38)
                    .rotationEffect(.degrees(stage == 0 ? 0 : 110))
                    .shadow(color: color.opacity(0.55), radius: 35)
                Text("Dropping the needle…").foregroundStyle(Palette.cream)
            }
        }
    }
}
