import SwiftUI

/// Records and plays back the learner's hummed melody.
struct MelodyRecorderView: View {
    @EnvironmentObject var state: StudioState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = VoiceRecorder()
    var body: some View {
        VStack(spacing: 22) {
            Text("MELODY")
                .font(.system(size: 28, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(Palette.gold)
                .shadow(color: Palette.gold.opacity(0.25), radius: 8)
            Vinyl(color: .mint, size: 190)
            Text("Hum a tune and capture it before it slips away.")
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
            Button {
                recorder.toggle()
            } label: {
                Label(recorder.isRecording ? "Stop Recording" : "Record Your Hum", systemImage: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .frame(maxWidth: .infinity).padding(15)
                    .background(recorder.isRecording ? Color.red : Color.mint, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(Palette.background)
            }
            if recorder.hasRecording {
                Button("▶ Play My Recording") { recorder.play() }.buttonStyle(.bordered)
            }
            if !recorder.message.isEmpty { Text(recorder.message).font(.caption).foregroundStyle(.gray) }
            Spacer()
            PrimaryAction(title: "Done — Complete Module") {
                if recorder.isRecording { recorder.toggle() }
                state.finish(3)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { dismiss() }
            }
        }
        .padding(20)
        .modifier(LessonBackground())
        .navigationTitle("")
    }
}
