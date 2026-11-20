import SwiftUI

/// Entry point for the melody drawing experience.
struct MelodyRecorderView: View {
    @EnvironmentObject var state: StudioState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 22) {
            Text("MELODY")
                .font(.system(size: 28, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(Palette.accent)
            Vinyl(color: Palette.accent, size: 190)
            Text("Turn your drawings into melody. Long strokes become sustained notes, and short strokes become quick notes.")
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)

            NavigationLink {
                MelodyDrawView().environmentObject(state)
            } label: {
                Label("Open Melody Canvas", systemImage: "paintbrush.pointed.fill")
                    .frame(maxWidth: .infinity).padding(15)
                    .background(Palette.accent, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }

            Text("For the best experience, hold your phone horizontally on the next page.")
                .font(.caption).foregroundStyle(Palette.muted).multilineTextAlignment(.center)

            Spacer()
            PrimaryAction(title: "Done — Complete Module") {
                state.finish(3)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { dismiss() }
            }
        }
        .padding(20)
        .modifier(LessonBackground())
        .navigationTitle("")
    }
}
