import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Interactive drawing canvas that turns strokes into melody.
struct MelodyDrawView: View {
    @EnvironmentObject var state: StudioState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audio = MusicEngine()
    @State private var strokes: [MelodyStroke] = []
    @State private var currentStroke: MelodyStroke?
    @State private var isPlaying = false
    @State private var canvasSize: CGSize = .zero
    @State private var playbackTask: Task<Void, Never>?
    @State private var playSession = UUID()
    @State private var selectedKey = 0

    private static let keyNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    // Pitch classes allowed in the selected major key; used to quantize drawn note pitches.
    private static let majorScale: Set<Int> = [0, 2, 4, 5, 7, 9, 11]

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            ZStack {
                Palette.background.ignoresSafeArea()

                if isLandscape {
                    canvas
                } else {
                    rotatePrompt
                }
            }
        }
        .navigationTitle("")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            requestLandscape()
        }
        .onDisappear {
            stopPlayback()
        }
    }

    private var rotatePrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "iphone.landscape")
                .font(.system(size: 56))
                .foregroundStyle(Palette.accent)
            Text("Rotate your phone horizontally")
                .font(.title3.bold())
                .foregroundStyle(Palette.cream)
            Text("Hold your device in landscape to draw your melody.")
                .font(.subheadline)
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private var canvas: some View {
        VStack(spacing: 10) {
            GeometryReader { canvasGeo in
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Palette.subtle.opacity(0.75))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Palette.accent.opacity(0.22), lineWidth: 1)
                        )

                    Canvas { context, canvasSize in
                        for stroke in strokes {
                            draw(stroke, in: &context)
                        }
                        if let stroke = currentStroke {
                            draw(stroke, in: &context)
                        }
                    }
                    .gesture(dragGesture(canvasSize: canvasGeo.size))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    if strokes.isEmpty && currentStroke == nil {
                        VStack(spacing: 8) {
                            Text("Draw to create melody")
                                .font(.headline)
                            Text("Long strokes = sustained notes • Short strokes = quick notes")
                                .font(.caption)
                                .foregroundStyle(Palette.muted)
                        }
                        .foregroundStyle(Palette.cream.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding()
                        .allowsHitTesting(false)
                    }
                }
                .onAppear { canvasSize = canvasGeo.size }
                .onChange(of: canvasGeo.size) { _, newSize in
                    canvasSize = newSize
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            HStack(spacing: 10) {
                Text("Key")
                    .font(.caption.bold())
                    .foregroundStyle(Palette.muted)
                Menu {
                    ForEach(0..<Self.keyNames.count, id: \.self) { index in
                        Button(Self.keyNames[index]) { selectedKey = index }
                    }
                } label: {
                    Label(Self.keyNames[selectedKey], systemImage: "tuningfork")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Palette.panel, in: Capsule())
                        .overlay(Capsule().stroke(Palette.accent.opacity(0.35)))
                }
                .tint(Palette.cream)
                Spacer()
                Text("Notes in \(Self.keyNames[selectedKey]) major")
                    .font(.caption2)
                    .foregroundStyle(Palette.muted)
            }
            .padding(.horizontal, 16)

            HStack(spacing: 12) {
                Button {
                    playAllStrokes()
                } label: {
                    Label(isPlaying ? "Playing…" : "Play", systemImage: isPlaying ? "speaker.wave.2.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Palette.accent)
                .disabled(strokes.isEmpty || isPlaying)

                Button {
                    stopPlayback()
                    strokes.removeAll()
                    currentStroke = nil
                } label: {
                    Label("Clear", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(strokes.isEmpty && currentStroke == nil)
            }
            .padding(.horizontal, 16)

            PrimaryAction(title: "Done — Complete Module") {
                stopPlayback()
                state.finish(3)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { dismiss() }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }

    private func dragGesture(canvasSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let point = value.location
                if var stroke = currentStroke {
                    stroke.points.append(point)
                    currentStroke = stroke
                } else {
                    currentStroke = MelodyStroke(
                        points: [point],
                        color: randomBlue(),
                        lineWidth: CGFloat.random(in: 5...9)
                    )
                }
            }
            .onEnded { _ in
                guard let stroke = currentStroke, stroke.points.count > 1 else {
                    currentStroke = nil
                    return
                }
                strokes.append(stroke)
                if !isPlaying {
                    playTone(for: stroke, in: canvasSize)
                }
                currentStroke = nil
            }
    }

    private func draw(_ stroke: MelodyStroke, in context: inout GraphicsContext) {
        guard stroke.points.count > 1 else { return }
        var path = Path()
        path.addLines(stroke.points)

        // Magical glow layers in varying blue tones
        var outerGlow = context
        outerGlow.addFilter(.blur(radius: 10))
        outerGlow.stroke(
            path,
            with: .color(stroke.color.opacity(0.35)),
            style: StrokeStyle(lineWidth: stroke.lineWidth + 14, lineCap: .round, lineJoin: .round)
        )

        var glowContext = context
        glowContext.addFilter(.blur(radius: 5))
        glowContext.stroke(
            path,
            with: .color(stroke.color.opacity(0.6)),
            style: StrokeStyle(lineWidth: stroke.lineWidth + 8, lineCap: .round, lineJoin: .round)
        )

        context.stroke(
            path,
            with: .color(stroke.color.opacity(0.98)),
            style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            path,
            with: .color(.white.opacity(0.5)),
            style: StrokeStyle(lineWidth: max(1.5, stroke.lineWidth * 0.35), lineCap: .round, lineJoin: .round)
        )
    }

    private func playTone(for stroke: MelodyStroke, in size: CGSize) {
        let (midi, duration) = note(for: stroke, in: size)
        audio.playTone(midi, duration: duration)
    }

    /// Plays all drawn strokes in order from left to right.
    /// `MusicEngine.playTone` schedules audio immediately, so playback timing is controlled here with sleeps.
    /// A `playSession` token prevents stale tasks from mutating state after stop/replay.
    private func playAllStrokes() {
        guard !strokes.isEmpty, !isPlaying else { return }
        stopPlayback()
        let session = UUID()
        playSession = session
        isPlaying = true

        let size = canvasSize == .zero ? CGSize(width: 1, height: 1) : canvasSize
        let ordered = strokes.sorted { strokeAnchorX($0) < strokeAnchorX($1) }

        playbackTask = Task { @MainActor in
            for stroke in ordered {
                if Task.isCancelled || playSession != session { return }
                let (midi, duration) = note(for: stroke, in: size)
                audio.playTone(midi, duration: duration)
                let pause = UInt64((duration + 0.08) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: pause)
            }
            if !Task.isCancelled && playSession == session {
                isPlaying = false
            }
        }
    }

    /// Stops any in-progress playback.
    private func stopPlayback() {
        playSession = UUID()
        playbackTask?.cancel()
        playbackTask = nil
        audio.stop()
        isPlaying = false
    }

    /// Computes the MIDI note and duration for a stroke using the canvas size.
    private func note(for stroke: MelodyStroke, in size: CGSize) -> (midi: Int, duration: Double) {
        let length = strokeLength(stroke.points)
        // Long strokes => sustained notes, short strokes => quick notes.
        let duration = min(max(Double(length) / 300.0, 0.12), 1.8)
        let avgY = stroke.points.map(\.y).reduce(0, +) / CGFloat(max(1, stroke.points.count))
        let height = max(size.height, 1)
        let normalized = min(max(avgY / height, 0), 1)
        // Higher on screen => higher pitch, restricted to the selected key.
        let notes = allowedNotes()
        guard !notes.isEmpty else { return (60, duration) }
        let index = Int(round((1.0 - Double(normalized)) * Double(notes.count - 1)))
        let midi = notes[min(max(index, 0), notes.count - 1)]
        return (midi, duration)
    }

    /// MIDI notes available in the selected key (major scale) over the playable range.
    private func allowedNotes() -> [Int] {
        (52...81).filter { midi in
            Self.majorScale.contains(((midi - selectedKey) % 12 + 12) % 12)
        }
    }

    /// Horizontal anchor used to order strokes from left to right.
    private func strokeAnchorX(_ stroke: MelodyStroke) -> CGFloat {
        guard !stroke.points.isEmpty else { return 0 }
        let minX = stroke.points.map(\.x).min() ?? 0
        let maxX = stroke.points.map(\.x).max() ?? 0
        return (minX + maxX) / 2
    }

    private func strokeLength(_ points: [CGPoint]) -> CGFloat {
        guard points.count > 1 else { return 0 }
        var total: CGFloat = 0
        for i in 1..<points.count {
            let dx = points[i].x - points[i - 1].x
            let dy = points[i].y - points[i - 1].y
            total += sqrt(dx * dx + dy * dy)
        }
        return total
    }

    private func randomBlue() -> Color {
        let palette: [Color] = [
            Color(red: 0.30, green: 0.66, blue: 1.00),
            Color(red: 0.20, green: 0.52, blue: 0.98),
            Color(red: 0.45, green: 0.78, blue: 1.00),
            Color(red: 0.10, green: 0.40, blue: 0.95),
            Color(red: 0.35, green: 0.85, blue: 1.00),
            Color(red: 0.18, green: 0.60, blue: 0.92),
            Color(red: 0.55, green: 0.82, blue: 1.00),
            Color(red: 0.12, green: 0.48, blue: 0.88)
        ]
        return palette.randomElement() ?? Palette.accent
    }

    private func requestLandscape() {
        #if os(iOS)
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return }
        if #available(iOS 16.0, *) {
            let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscape)
            scene.requestGeometryUpdate(prefs)
        }
        #endif
    }
}

private struct MelodyStroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color
    var lineWidth: CGFloat
}
