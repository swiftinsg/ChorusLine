import SwiftUI

/// Transition shown while a module is opening.
/// `stage` drives the scale/rotation animation; a reserved vinyl frame keeps text from clipping.
struct OpeningRecordAnimation: View {
    let color: Color
    let stage: Int
    var accent: Color = Palette.accent
    var body: some View {
        GeometryReader { geo in
            let baseSize = min(210, min(geo.size.width, geo.size.height) * 0.4)
            let maxScale = min(1.25, max(0.85, (geo.size.height * 0.36) / max(baseSize, 1)))
            let vinylArea = baseSize * max(maxScale, 0.48)
            ZStack {
                Palette.background.opacity(0.97).ignoresSafeArea()
                VStack(spacing: 36) {
                    Text("NOW LOADING")
                        .font(.headline)
                        .tracking(4)
                        .foregroundStyle(accent)
                    // Stage 0: smaller/starting pose. Stage 1+: enlarged "needle drop" pose.
                    Vinyl(color: color, spinning: true, size: baseSize)
                        .scaleEffect(stage == 0 ? 0.48 : maxScale)
                        .rotationEffect(.degrees(stage == 0 ? 0 : 110))
                        .shadow(color: color.opacity(0.5), radius: 30)
                        .frame(width: vinylArea, height: vinylArea)
                    Text("Dropping the needle…")
                        .foregroundStyle(Palette.cream)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
