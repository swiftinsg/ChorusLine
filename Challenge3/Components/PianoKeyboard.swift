// -----------------------------------------------------------------------------
// FILE SUMMARY — Components/PianoKeyboard.swift
// -----------------------------------------------------------------------------
// PURPOSE: One-octave piano keyboard (MIDI 60–71) that reports the tapped note so
//          callers can play or transpose it.
//
// TYPES / FUNCTIONS:
//   • KeySpec — lightweight key data: MIDI id, optional letter label and the
//     number of white keys to its left (used for black-key positioning).
//   • body — measures the container, lays out seven white keys in an HStack and
//     offsets five narrower/shorter black keys on top. Each tap calls `onNote`
//     with that key's MIDI number.
//   • PianoKeyView.body — draws a rounded key with outline, optional label and
//     shadow; a tap briefly highlights it for 0.16 s before returning to rest.
//   • fillColor — chooses the pressed or resting fill for black/white keys.
//
// Used by PianoView and SandboxView for key selection and transposition.
// -----------------------------------------------------------------------------

// Import SwiftUI for the View protocol, geometry helpers, buttons, and shape styling.
import SwiftUI

/// A one-octave piano keyboard. Pressing a key reports its MIDI note so the
/// caller can respond (for example, to transpose a chord progression).
// A single-octave piano keyboard view that reports the MIDI note number of each tapped key.
struct PianoKeyboard: View {
    // Callback Given the MIDI note (e.g., 60 = middle C) of the pressed key so the parent can play or transpose it.
    let onNote: (Int) -> Void

    // Lightweight description of one key: its MIDI note, optional letter label, and horizontal placement.
    private struct KeySpec: Identifiable {
        // MIDI note number, also used as the stable identity for ForEach.
        let id: Int
        // Optional note name shown on white keys; black keys have no label.
        let name: String?
        // How many white keys sit to the left of this key, used to position black keys.
        let whiteOffset: Int
    }

    // The seven white keys of the octave (C through B), with MIDI notes from 60 upward.
    private let whiteKeys: [KeySpec] = [
        // C, D, E, F: consecutive white keys with offsets 0 through 3.
        .init(id: 60, name: "C", whiteOffset: 0), .init(id: 62, name: "D", whiteOffset: 1),
        // E and F sit at offsets 2 and 3; no black key between them.
        .init(id: 64, name: "E", whiteOffset: 2), .init(id: 65, name: "F", whiteOffset: 3),
        // G, A, B fill out the rest of the octave at offsets 4 through 6.
        .init(id: 67, name: "G", whiteOffset: 4), .init(id: 69, name: "A", whiteOffset: 5),
        // B is the final white key before the octave repeats at MIDI 72.
        .init(id: 71, name: "B", whiteOffset: 6)
    ]
    // whiteOffset is the number of white keys to the left of the black key.
    // The five black keys (C#, D#, F#, G#, A#), positioned between specific white keys.
    private let blackKeys: [KeySpec] = [
        // C# and D# sit after the first and second white keys; labels are omitted.
        .init(id: 61, name: nil, whiteOffset: 1), .init(id: 63, name: nil, whiteOffset: 2),
        // F# and G# sit after the fourth and fifth white keys.
        .init(id: 66, name: nil, whiteOffset: 4), .init(id: 68, name: nil, whiteOffset: 5),
        // A# sits after the sixth white key, just before B.
        .init(id: 70, name: nil, whiteOffset: 6)
    ]

    // The keyboard measures its container so key widths scale to any screen size.
    var body: some View {
        // GeometryReader provides the available width and height for laying out the keys.
        GeometryReader { proxy in
            // Each white key takes one-seventh of the total width.
            let whiteWidth = proxy.size.width / CGFloat(whiteKeys.count)
            // Black keys are narrower than white keys, as on a real piano.
            let blackWidth = whiteWidth * 0.62
            // Black keys are also shorter, leaving space above for the raised white-key area.
            let blackHeight = proxy.size.height * 0.62

            // Layer the black keys on top of the white keys, anchored at the top-left.
            ZStack(alignment: .topLeading) {
                // Lay the white keys out side by side with no gaps.
                HStack(spacing: 0) {
                    // Create one button per white key from the whiteKeys data.
                    ForEach(whiteKeys) { key in
                        // A white key reports its MIDI note through onNote when tapped.
                        PianoKeyView(isBlack: false, label: key.name) { onNote(key.id) }
                            // Size the key to its equal share of the keyboard width and full height.
                            .frame(width: whiteWidth, height: proxy.size.height)
                    }
                }
                // Draw the black keys after the whites so they overlap visually like a real keyboard.
                ForEach(blackKeys) { key in
                    // A black key reports its MIDI note (including sharps) when tapped.
                    PianoKeyView(isBlack: true, label: nil) { onNote(key.id) }
                        // Give each black key its narrower, shorter frame.
                        .frame(width: blackWidth, height: blackHeight)
                        // Position it centered over the boundary after its whiteOffset white keys.
                        .offset(x: CGFloat(key.whiteOffset) * whiteWidth - blackWidth / 2)
                }
            }
        }
    }
}

// A single drawable piano key that briefly highlights when pressed.
private struct PianoKeyView: View {
    // Whether this key is black, which controls its color, corner radius, and shadow.
    let isBlack: Bool
    // Optional letter shown on white keys; nil for black keys.
    let label: String?
    // Closure invoked when the key is tapped, supplied by the parent keyboard.
    let action: () -> Void
    // Tracks the brief pressed highlight so a tap gives visual feedback.
    @State private var pressed = false

    // Builds the key as a plain button with a rounded rectangle, outline, label, and shadow.
    var body: some View {
        // Use a Button so taps are handled accessibly and with standard control behavior.
        Button {
            // Notify the caller of the tapped key's MIDI note so it can play the sound.
            action()
            // Turn on the pressed highlight immediately.
            pressed = true
            // Schedule the highlight to turn off shortly after, mimicking a key release.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { pressed = false }
        } label: {
            // Draw the key body with slightly different corner radii for black and white keys.
            RoundedRectangle(cornerRadius: isBlack ? 3 : 4)
                // Fill with either the pressed color or the resting color computed below.
                .fill(fillColor)
                // Add a thin outline: strong on black keys, subtle on white ones.
                .overlay {
                    // Match the body's corner radius so the stroke lines up exactly.
                    RoundedRectangle(cornerRadius: isBlack ? 3 : 4)
                        // Use a dark outline, more opaque for black keys to define their edge.
                        .stroke(Color.black.opacity(isBlack ? 0.9 : 0.25), lineWidth: 1)
                }
                // Place the optional note letter near the bottom of the key.
                .overlay(alignment: .bottom) {
                    // Unwrap the optional label so nothing is drawn when it is nil.
                    if let label {
                        // Show the note name (e.g., "C") on the key face.
                        Text(label)
                            // Use a very small caption font to fit inside the key.
                            .font(.caption2)
                            // Keep the letter muted so it doesn't overwhelm the keyboard.
                            .foregroundStyle(.black.opacity(0.45))
                            // Lift the label slightly above the bottom edge.
                            .padding(.bottom, 7)
                    }
                }
                // Add a drop shadow: deeper for black keys so they appear raised above the whites.
                .shadow(color: .black.opacity(isBlack ? 0.4 : 0.08), radius: isBlack ? 2 : 1, y: isBlack ? 2 : 1)
        }
        // Remove the default button chrome so the custom key drawing is the only visible style.
        .buttonStyle(.plain)
    }

    // Chooses the key's fill color based on pressed state and black/white key type.
    private var fillColor: Color {
        // While pressed, show an accent flash on black keys and a gray press on white keys.
        if pressed { return isBlack ? Palette.accent : Color(white: 0.78) }
        // At rest, black keys are nearly black and white keys are pure white.
        return isBlack ? Color(white: 0.06) : .white
    }
}
