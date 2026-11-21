// Import SwiftUI for views, gestures, Canvas rendering, and state management.
import SwiftUI
// Only compile the UIKit import when the target platform provides UIKit.
#if canImport(UIKit)
// Import UIKit so the view can request a landscape orientation on iOS.
import UIKit
// End of the UIKit-only import block.
#endif

// Declare the SwiftUI view for the drawing canvas module.
/// Interactive drawing canvas that turns strokes into melody.
struct MelodyDrawView: View {
    // Read the shared StudioState from the environment so finishing updates module progress.
    @EnvironmentObject var state: StudioState
    // Get SwiftUI's dismiss action so the view can close itself once the module is done.
    @Environment(\.dismiss) private var dismiss
    // Create one synthesizer engine owned by this view to play the generated notes.
    @StateObject private var audio = MusicEngine()
    // Store the user's completed strokes; each one will become a note in the melody.
    @State private var strokes: [MelodyStroke] = []
    // Track the stroke currently being dragged before it is committed to the melody.
    @State private var currentStroke: MelodyStroke?
    // Track whether playback is active so controls can disable themselves.
    @State private var isPlaying = false
    // Remember the canvas size so stroke coordinates can be mapped to musical pitches.
    @State private var canvasSize: CGSize = .zero
    // Hold the async playback task so it can be cancelled when playback stops.
    @State private var playbackTask: Task<Void, Never>?
    // Identify the current playback run so a stale task cannot change the UI later.
    @State private var playSession = UUID()
    // Store the chosen key as a pitch class from 0 (C) to 11 (B).
    @State private var selectedKey = 0

    // Provide the display names for the twelve pitch classes used by the key picker.
    private static let keyNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    // Define major-scale pitch classes so generated notes can be limited to the chosen key.
    private static let majorScale: Set<Int> = [0, 2, 4, 5, 7, 9, 11]

    // Build the view hierarchy: show the canvas in landscape, otherwise a rotate prompt.
    var body: some View {
        // Read the available space to determine whether the device is in landscape.
        GeometryReader { proxy in
            // Treat a wider-than-tall container as landscape, where drawing is allowed.
            let isLandscape = proxy.size.width > proxy.size.height
            // Layer the background color behind either the canvas or the rotate prompt.
            ZStack {
                // Fill the whole screen with the app background, ignoring safe-area insets.
                Palette.background.ignoresSafeArea()

                // In landscape, present the interactive drawing canvas.
                if isLandscape {
                    // Render the canvas that handles drawing and playback controls.
                    canvas
                // In portrait, ask the user to rotate the device instead.
                } else {
                    // Show the instruction screen explaining that landscape is required.
                    rotatePrompt
                }
            }
        }
        // Hide the navigation title to give the drawing area more room.
        .navigationTitle("")
        // Apply the compact navigation bar style only on iOS.
        #if os(iOS)
        // Keep the navigation bar inline so it does not consume vertical space.
        .navigationBarTitleDisplayMode(.inline)
        // End of the iOS-only navigation bar modifier.
        #endif
        // Request landscape orientation when this view first appears.
        .onAppear {
            // Ask the system to rotate the window into landscape for drawing.
            requestLandscape()
        }
        // Stop any sound when this view leaves the screen.
        .onDisappear {
            // Cancel playback and silence the audio engine before leaving.
            stopPlayback()
        }
    }

    // Build the portrait-mode screen that asks the user to rotate the device.
    private var rotatePrompt: some View {
        // Stack the icon and instruction text vertically with even spacing.
        VStack(spacing: 16) {
            // Show an SF Symbol that visually suggests holding the phone sideways.
            Image(systemName: "iphone.landscape")
                // Make the rotate icon large so it is immediately noticeable.
                .font(.system(size: 56))
                // Tint the icon with the app's accent color for emphasis.
                .foregroundStyle(Palette.accent)
            // Give a direct instruction to rotate the device horizontally.
            Text("Rotate your phone horizontally")
                // Use a bold title font so the primary instruction stands out.
                .font(.title3.bold())
                // Color the instruction in the app's cream text color.
                .foregroundStyle(Palette.cream)
            // Explain why landscape is needed: drawing and note mapping happen there.
            Text("Hold your device in landscape to draw your melody.")
                // Use a smaller subtitle font for the secondary explanation.
                .font(.subheadline)
                // Mute the secondary text so it reads as supporting detail.
                .foregroundStyle(Palette.muted)
                // Center the text in case it wraps across multiple lines.
                .multilineTextAlignment(.center)
        }
        // Add generous padding so the prompt is not cramped against the screen edges.
        .padding(32)
    }

    // Build the landscape drawing interface with the canvas and control buttons.
    private var canvas: some View {
        // Arrange the drawing area and controls vertically with small gaps.
        VStack(spacing: 10) {
            // Measure the drawing area so gesture coordinates can be mapped to notes.
            GeometryReader { canvasGeo in
                // Layer the background, stroke rendering, and the placeholder hint.
                ZStack {
                    // Draw a rounded rectangle that serves as the canvas background.
                    RoundedRectangle(cornerRadius: 18)
                        // Fill it with a subtle translucent color so strokes read clearly.
                        .fill(Palette.subtle.opacity(0.75))
                        // Add a thin outline on top of the filled background.
                        .overlay(
                            // Use a matching rounded rectangle for the outline shape.
                            RoundedRectangle(cornerRadius: 18)
                                // Draw a faint accent-colored border to define the canvas edge.
                                .stroke(Palette.accent.opacity(0.22), lineWidth: 1)
                        )

                    // Use SwiftUI's Canvas to render strokes with custom glow effects.
                    Canvas { context, canvasSize in
                        // Loop over committed strokes so each one is drawn once.
                        for stroke in strokes {
                            // Render this committed stroke into the graphics context.
                            draw(stroke, in: &context)
                        }
                        // Also draw the in-progress stroke so the user sees live feedback.
                        if let stroke = currentStroke {
                            // Render the active drag stroke on top of committed ones.
                            draw(stroke, in: &context)
                        }
                    }
                    // Attach the drag gesture that records touch points in canvas coordinates.
                    .gesture(dragGesture(canvasSize: canvasGeo.size))
                    // Clip any drawing that extends outside the rounded canvas area.
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    // Show a hint only when the canvas has no strokes at all.
                    if strokes.isEmpty && currentStroke == nil {
                        // Stack the hint title and its explanation vertically.
                        VStack(spacing: 8) {
                            // Tell the user that drawing creates the melody.
                            Text("Draw to create melody")
                                // Emphasize the hint title with a headline font.
                                .font(.headline)
                            // Explain the stroke-length to note-duration mapping.
                            Text("Long strokes = sustained notes • Short strokes = quick notes")
                                // Use a small caption font for the secondary hint.
                                .font(.caption)
                                // Mute the secondary hint text.
                                .foregroundStyle(Palette.muted)
                        }
                        // Color the whole hint stack in cream, slightly softened.
                        .foregroundStyle(Palette.cream.opacity(0.9))
                        // Center the hint text when it wraps onto multiple lines.
                        .multilineTextAlignment(.center)
                        // Add default padding so the hint is not flush with the canvas edge.
                        .padding()
                        // Let touches pass through the hint to the canvas gesture beneath.
                        .allowsHitTesting(false)
                    }
                }
                // Cache the canvas size when it first appears for pitch mapping.
                .onAppear { canvasSize = canvasGeo.size }
                // Update the cached size whenever the canvas resizes, such as on rotation.
                .onChange(of: canvasGeo.size) { _, newSize in
                    // Store the new size so vertical positions still map to the right notes.
                    canvasSize = newSize
                }
            }
            // Add horizontal breathing room around the canvas.
            .padding(.horizontal, 12)
            // Add a small gap above the canvas.
            .padding(.top, 8)

            // Lay out the key selector row horizontally.
            HStack(spacing: 10) {
                // Label the musical key picker.
                Text("Key")
                    // Make the label small but bold.
                    .font(.caption.bold())
                    // Mute the label color.
                    .foregroundStyle(Palette.muted)
                // Create a menu listing the twelve selectable musical keys.
                Menu {
                    // Generate one button per pitch-class name in keyNames.
                    ForEach(0..<Self.keyNames.count, id: \.self) { index in
                        // Selecting a key updates the pitch class used to filter notes.
                        Button(Self.keyNames[index]) { selectedKey = index }
                    }
                // Build the menu's visible label from the currently selected key.
                } label: {
                    // Show the selected key name alongside a tuning-fork icon.
                    Label(Self.keyNames[selectedKey], systemImage: "tuningfork")
                        // Style the label text as a bold subheadline.
                        .font(.subheadline.bold())
                        // Add pill-like horizontal and vertical padding around the label.
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        // Fill a capsule-shaped background behind the label.
                        .background(Palette.panel, in: Capsule())
                        // Outline the capsule with a faint accent stroke.
                        .overlay(Capsule().stroke(Palette.accent.opacity(0.35)))
                }
                // Tint the menu with the app's cream color.
                .tint(Palette.cream)
                // Push the following note-range text to the right side of the row.
                Spacer()
                // Tell the user which major scale constrains the generated notes.
                Text("Notes in \(Self.keyNames[selectedKey]) major")
                    // Use the smallest caption font for this helper text.
                    .font(.caption2)
                    // Mute the helper text.
                    .foregroundStyle(Palette.muted)
            }
            // Add horizontal padding to the key row.
            .padding(.horizontal, 16)

            // Lay out the Play and Clear buttons side by side.
            HStack(spacing: 12) {
                // Define the Play button whose action starts full melody playback.
                Button {
                    // Play all drawn strokes in left-to-right order.
                    playAllStrokes()
                // Build the Play button's visible label.
                } label: {
                    // Switch title and icon to show whether notes are currently playing.
                    Label(isPlaying ? "Playing…" : "Play", systemImage: isPlaying ? "speaker.wave.2.fill" : "play.fill")
                        // Let the button stretch across the available width.
                        .frame(maxWidth: .infinity)
                }
                // Give Play a filled, prominent button style.
                .buttonStyle(.borderedProminent)
                // Color the Play button with the accent color.
                .tint(Palette.accent)
                // Disable Play when there is nothing to play or playback is already running.
                .disabled(strokes.isEmpty || isPlaying)

                // Define the Clear button whose action resets the canvas.
                Button {
                    // Stop any sound before clearing the drawing.
                    stopPlayback()
                    // Remove all committed strokes from the melody.
                    strokes.removeAll()
                    // Discard any stroke that is still in progress.
                    currentStroke = nil
                // Build the Clear button's visible label.
                } label: {
                    // Show a trash icon together with the Clear title.
                    Label("Clear", systemImage: "trash")
                        // Let Clear stretch to match the Play button's width.
                        .frame(maxWidth: .infinity)
                }
                // Use a lighter bordered style for this secondary action.
                .buttonStyle(.bordered)
                // Disable Clear when there is nothing on the canvas to remove.
                .disabled(strokes.isEmpty && currentStroke == nil)
            }
            // Add horizontal padding to the button row.
            .padding(.horizontal, 16)

            // Provide the completion button that marks module 3 as finished.
            PrimaryAction(title: "Done — Complete Module") {
                // Silence audio before leaving the module.
                stopPlayback()
                // Record completion of module 3 in the shared app state.
                state.finish(3)
                // Wait briefly for the completion animation, then close this view.
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { dismiss() }
            }
            // Add horizontal padding around the completion button.
            .padding(.horizontal, 16)
            // Add bottom padding so the button clears the screen edge.
            .padding(.bottom, 10)
        }
    }

    // Create the drag gesture that captures touch points and commits them as strokes.
    private func dragGesture(canvasSize: CGSize) -> some Gesture {
        // Start receiving updates immediately on touch down, even before any movement.
        DragGesture(minimumDistance: 0)
            // Append points as the finger moves so the line follows the drag.
            .onChanged { value in
                // Read the current touch location in the canvas's local coordinate space.
                let point = value.location
                // If a stroke is already in progress, add this point to it.
                if var stroke = currentStroke {
                    // Store the touch point so later updates can draw a connected stroke.
                    stroke.points.append(point)
                    // Write the updated stroke back to state so the Canvas redraws it.
                    currentStroke = stroke
                // Otherwise, begin a brand-new stroke with this first touch point.
                } else {
                    // Create a fresh stroke to hold this drag's points and appearance.
                    currentStroke = MelodyStroke(
                        // Seed the stroke with the initial touch location.
                        points: [point],
                        // Pick a random blue shade so each stroke looks distinct.
                        color: randomBlue(),
                        // Vary the line width slightly for a hand-drawn appearance.
                        lineWidth: CGFloat.random(in: 5...9)
                    )
                }
            }
            // When the drag ends, validate and commit the stroke, then play its note.
            .onEnded { _ in
                // Ignore taps that never became a real stroke (fewer than two points).
                guard let stroke = currentStroke, stroke.points.count > 1 else {
                    // Discard the invalid stroke so drawing can start fresh.
                    currentStroke = nil
                    // Exit early because there is nothing to commit or play.
                    return
                }
                // Save the finished stroke so it is drawn and played with the others.
                strokes.append(stroke)
                // Only preview the note immediately when a full playback is not running.
                if !isPlaying {
                    // Synthesize and play the note mapped from this stroke's shape.
                    playTone(for: stroke, in: canvasSize)
                }
                // Clear the active stroke so the next drag starts a new one.
                currentStroke = nil
            }
    }

    // Render one stroke with layered blue glows using SwiftUI's graphics context.
    private func draw(_ stroke: MelodyStroke, in context: inout GraphicsContext) {
        // Skip strokes that have no drawable line segment.
        guard stroke.points.count > 1 else { return }
        // Start building a path from the stroke's recorded touch points.
        var path = Path()
        // Connect the points into a continuous line following the finger's movement.
        path.addLines(stroke.points)

        // Magical glow layers in varying blue tones
        // Copy the context for the widest, softest outer glow layer.
        var outerGlow = context
        // Blur this layer heavily to create a diffuse halo around the stroke.
        outerGlow.addFilter(.blur(radius: 10))
        // Draw the blurred outer glow along the recorded path.
        outerGlow.stroke(
            // Use the stroke's path as the shape to paint.
            path,
            // Paint the outer glow in the stroke's blue at low opacity.
            with: .color(stroke.color.opacity(0.35)),
            // Make the glow much wider than the line, with rounded ends and joins.
            style: StrokeStyle(lineWidth: stroke.lineWidth + 14, lineCap: .round, lineJoin: .round)
        )

        // Copy the context again for a tighter, brighter inner glow.
        var glowContext = context
        // Blur moderately so this glow is brighter but still soft.
        glowContext.addFilter(.blur(radius: 5))
        // Draw the inner glow along the same path.
        glowContext.stroke(
            // Reuse the stroke's path for this layer.
            path,
            // Paint the inner glow in a more visible shade of the stroke color.
            with: .color(stroke.color.opacity(0.6)),
            // Widen the line moderately with rounded caps and joins.
            style: StrokeStyle(lineWidth: stroke.lineWidth + 8, lineCap: .round, lineJoin: .round)
        )

        // Draw the solid core of the stroke on the original context.
        context.stroke(
            // Follow the same recorded path for the core line.
            path,
            // Paint the core in nearly opaque blue.
            with: .color(stroke.color.opacity(0.98)),
            // Use the stroke's actual width with rounded ends and joins.
            style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round)
        )
        // Add a thin white highlight to make the stroke look like a beam of light.
        context.stroke(
            // Apply the highlight along the same path.
            path,
            // Use semi-transparent white for a glossy sheen.
            with: .color(.white.opacity(0.5)),
            // Keep the highlight thin, but at least 1.5 points wide.
            style: StrokeStyle(lineWidth: max(1.5, stroke.lineWidth * 0.35), lineCap: .round, lineJoin: .round)
        )
    }

    // Convert a stroke into a note and hand it to the synthesizer for playback.
    private func playTone(for stroke: MelodyStroke, in size: CGSize) {
        // Compute the MIDI pitch and duration from the stroke's geometry and canvas size.
        let (midi, duration) = note(for: stroke, in: size)
        // Ask MusicEngine to synthesize and play that note for the given duration.
        audio.playTone(midi, duration: duration)
    }

    // Define the action behind the Play button for the full drawing.
    /// Plays all drawn strokes in order from left to right.
    private func playAllStrokes() {
        // Do nothing if there are no strokes or a playback is already in progress.
        guard !strokes.isEmpty, !isPlaying else { return }
        // Clear any stale playback state before starting a fresh sequence.
        stopPlayback()
        // Create a unique token so this run can be told apart from later runs.
        let session = UUID()
        // Store the token so stopPlayback can invalidate this run.
        playSession = session
        // Mark playback active so the UI can disable the Play button.
        isPlaying = true

        // Avoid dividing by zero by using a 1x1 size if the canvas was never measured.
        let size = canvasSize == .zero ? CGSize(width: 1, height: 1) : canvasSize
        // Sort strokes by horizontal center so the melody reads left to right.
        let ordered = strokes.sorted { strokeAnchorX($0) < strokeAnchorX($1) }

        // Run the note sequence on the main actor so state and audio calls stay safe.
        playbackTask = Task { @MainActor in
            // Play each stroke in sequence, one note at a time.
            for stroke in ordered {
                // Stop if the task was cancelled or a newer playback took over.
                if Task.isCancelled || playSession != session { return }
                // Map this stroke's vertical position and length to a note.
                let (midi, duration) = note(for: stroke, in: size)
                // Synthesize and play the note through MusicEngine.
                audio.playTone(midi, duration: duration)
                // Convert the note length plus a small gap into nanoseconds to wait.
                let pause = UInt64((duration + 0.08) * 1_000_000_000)
                // Sleep until the note finishes before moving to the next stroke.
                try? await Task.sleep(nanoseconds: pause)
            }
            // Only update the UI if this playback run is still the active one.
            if !Task.isCancelled && playSession == session {
                // Mark playback finished so the Play button becomes available again.
                isPlaying = false
            }
        }
    }

    // Define the cleanup used by Stop, Clear, and Done to silence the module.
    /// Stops any in-progress playback.
    private func stopPlayback() {
        // Invalidate the current session so any running playback loop exits.
        playSession = UUID()
        // Cancel the async task that is sleeping between notes.
        playbackTask?.cancel()
        // Release the reference to the cancelled task.
        playbackTask = nil
        // Silence MusicEngine immediately so no note keeps ringing.
        audio.stop()
        // Reset the UI state so Play can be used again.
        isPlaying = false
    }

    // Define the core stroke-to-note mapping shared by preview and sequence playback.
    /// Computes the MIDI note and duration for a stroke using the canvas size.
    private func note(for stroke: MelodyStroke, in size: CGSize) -> (midi: Int, duration: Double) {
        // Measure the total drawn distance to decide how long the note should last.
        let length = strokeLength(stroke.points)
        // Long strokes => sustained notes, short strokes => quick notes.
        let duration = min(max(Double(length) / 300.0, 0.12), 1.8)
        // Average the stroke's y-coordinates to find its vertical center in the canvas.
        let avgY = stroke.points.map(\.y).reduce(0, +) / CGFloat(max(1, stroke.points.count))
        // Guard against a zero canvas height before normalizing the y position.
        let height = max(size.height, 1)
        // Convert the y position into a 0...1 fraction of the canvas height.
        let normalized = min(max(avgY / height, 0), 1)
        // Higher on screen => higher pitch, restricted to the selected key.
        let notes = allowedNotes()
        // Fall back to middle C (MIDI 60) if no notes are available for the key.
        guard !notes.isEmpty else { return (60, duration) }
        // Invert y so the top of the canvas maps to the highest note in the scale.
        let index = Int(round((1.0 - Double(normalized)) * Double(notes.count - 1)))
        // Clamp the index into range and pick the matching MIDI note.
        let midi = notes[min(max(index, 0), notes.count - 1)]
        // Return the mapped pitch and duration to the caller.
        return (midi, duration)
    }

    // Define which pitches satisfy both the selected key and the allowed register.
    /// MIDI notes available in the selected key (major scale) over the playable range.
    private func allowedNotes() -> [Int] {
        // Consider only MIDI 52...81, a comfortable range of roughly E3 to A5.
        (52...81).filter { midi in
            // Keep a pitch only if its note relative to the chosen key is in the major scale.
            Self.majorScale.contains(((midi - selectedKey) % 12 + 12) % 12)
        }
    }

    // Define how a stroke's horizontal center is computed for playback ordering.
    /// Horizontal anchor used to order strokes from left to right.
    private func strokeAnchorX(_ stroke: MelodyStroke) -> CGFloat {
        // Return a neutral anchor if the stroke contains no points.
        guard !stroke.points.isEmpty else { return 0 }
        // Find the leftmost touch point in the stroke.
        let minX = stroke.points.map(\.x).min() ?? 0
        // Find the rightmost touch point in the stroke.
        let maxX = stroke.points.map(\.x).max() ?? 0
        // Use the midpoint so a wide stroke is ordered by its center.
        return (minX + maxX) / 2
    }

    // Sum distances between consecutive points to measure how far the finger moved.
    private func strokeLength(_ points: [CGPoint]) -> CGFloat {
        // A single point has no length, so return zero.
        guard points.count > 1 else { return 0 }
        // Start the running distance total at zero.
        var total: CGFloat = 0
        // Walk each adjacent pair of points to add up the polyline length.
        for i in 1..<points.count {
            // Compute the horizontal step between this point and the previous one.
            let dx = points[i].x - points[i - 1].x
            // Compute the vertical step between this point and the previous one.
            let dy = points[i].y - points[i - 1].y
            // Add this segment's straight-line distance using Pythagoras.
            total += sqrt(dx * dx + dy * dy)
        }
        // Return the full drawn length that determines the note's duration.
        return total
    }

    // Pick a random shade from a curated blue palette for visual variety.
    private func randomBlue() -> Color {
        // List the hand-picked blue colors available for new strokes.
        let palette: [Color] = [
            // A bright sky blue.
            Color(red: 0.30, green: 0.66, blue: 1.00),
            // A deeper azure blue.
            Color(red: 0.20, green: 0.52, blue: 0.98),
            // A soft light blue.
            Color(red: 0.45, green: 0.78, blue: 1.00),
            // A strong royal blue.
            Color(red: 0.10, green: 0.40, blue: 0.95),
            // A vivid cyan-blue.
            Color(red: 0.35, green: 0.85, blue: 1.00),
            // A medium ocean blue.
            Color(red: 0.18, green: 0.60, blue: 0.92),
            // A pale ice blue.
            Color(red: 0.55, green: 0.82, blue: 1.00),
            // A dark steel blue.
            Color(red: 0.12, green: 0.48, blue: 0.88)
        ]
        // Return a random palette entry, falling back to the accent color if needed.
        return palette.randomElement() ?? Palette.accent
    }

    // Ask the system to rotate the window to landscape so drawing has enough room.
    private func requestLandscape() {
        // Orientation requests are available only on iOS.
        #if os(iOS)
        // Find the active window scene needed to request a geometry update.
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return }
        // The geometry-update API exists only on iOS 16 and later.
        if #available(iOS 16.0, *) {
            // Build a preference object requesting landscape interface orientation.
            let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscape)
            // Send the preference to the window scene to trigger rotation.
            scene.requestGeometryUpdate(prefs)
        }
        // End of the iOS-only orientation code.
        #endif
    }
}

// Model one drawn stroke as identifiable data holding its points and visual styling.
private struct MelodyStroke: Identifiable {
    // Give each stroke a stable identity for SwiftUI's rendering and diffs.
    let id = UUID()
    // Store the ordered touch points that define the stroke's shape.
    var points: [CGPoint]
    // Store the chosen blue shade used when drawing the stroke.
    var color: Color
    // Store the line width used for rendering and the glow layers.
    var lineWidth: CGFloat
}
