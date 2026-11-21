// Import SwiftUI for the view, state, and layout APIs used throughout this screen.
import SwiftUI
// Only compile the UIKit import on platforms that actually provide UIKit.
#if canImport(UIKit)
// UIKit supplies the selection haptic used when a learner taps a chord.
import UIKit
// End of the UIKit-only import block.
#endif

/// Lets the learner play any chord progression in any key on a piano.
// Declare a SwiftUI view whose body describes the chord-piano screen.
struct PianoView: View {
    // Read the shared app state so the chosen progression carries over between modules.
    @EnvironmentObject var state: StudioState
    // Get SwiftUI's dismiss action so the Done button can close this screen.
    @Environment(\.dismiss) private var dismiss
    // Own one audio engine for the view's lifetime so playback survives UI redraws.
    @StateObject private var audio = MusicEngine()
    // Track the chosen progression by id; changing it rebuilds the chord columns.
    @State private var chosen = 0
    // Track the key as a semitone offset from C, from 0 through 11.
    @State private var selectedKey = 0
    // Remember the readable key name shown in the "Playing in ..." label.
    @State private var lastKey = "C"
    // Track extra semitone shifts applied to the progression, reset whenever the key changes.
    @State private var transposeOffset = 0
    // Hold the tempo bound to the slider, measured in beats per minute.
    @State private var bpm: Double = 100
    // Map a pitch class (MIDI note modulo 12) to a readable note name.
    private static let keyNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    // List the pitch classes of the major scale to test whether chords fit the chosen key.
    private static let majorScale: Set<Int> = [0, 2, 4, 5, 7, 9, 11]

    /// Progressions whose chords are all diatonic to the selected song key.
    // Recompute the available progressions whenever the selected key changes.
    private var filteredProgressions: [Progression] {
        // Start with every progression and keep only those that pass the chord test below.
        progressions.filter { progression in
            // A progression qualifies only if all of its chords are in the key.
            progression.notes.allSatisfy { chord in
                // A chord qualifies only if every MIDI note in it belongs to the key's scale.
                chord.allSatisfy { midi in
                    // Shift the note relative to the key into 0...11, then check scale membership.
                    Self.majorScale.contains(((midi - selectedKey) % 12 + 12) % 12)
                }
            }
        }
    }

    // SwiftUI calls this property to build the screen and rebuild it when state changes.
    var body: some View {
        // Allow vertical scrolling because the keyboard and chord columns can be tall.
        ScrollView {
        // Stack the sections vertically with a 16-point gap between them.
        VStack(spacing: 16) {
            // Place the explanatory text on the left and the two menus on the right.
            HStack(alignment: .top, spacing: 12) {
                // Group the heading and its helper text, left-aligned.
                VStack(alignment: .leading, spacing: 4) {
                    // Show the screen title in a bold title font.
                    Text("CHORD PIANO").font(.title.bold())
                    // Explain that chord columns play sound while piano keys change the key.
                    Text("Choose a key and progression, tap a chord column to hear it, or press a piano key to transpose the progression.")
                        // Style the explanation as small, muted text.
                        .font(.caption).foregroundStyle(Palette.muted)
                        // Let the explanation wrap instead of being clipped to one line.
                        .fixedSize(horizontal: false, vertical: true)
                }
                // Push the menus to the right side of the header row.
                Spacer(minLength: 8)
                // Stack the key picker above the progression picker, right-aligned.
                VStack(alignment: .trailing, spacing: 8) {
                    // Show the key-selection menu.
                    keyMenu
                    // Show the progression-selection menu.
                    progressionMenu
                }
            }

            // If a progression matches the chosen id, show its descriptive details.
            if let selected = progressions.first(where: { $0.id == chosen }) {
                // Group the name and mood with only a small gap between them.
                VStack(spacing: 3) {
                    // Show the progression name in the accent color.
                    Text(selected.name)
                        // Use a bold headline font to make the name prominent.
                        .font(.headline).foregroundStyle(Palette.accent)
                    // Show the mood tag as secondary musical context.
                    Text(selected.mood)
                        // Use muted caption text so the mood does not compete with the name.
                        .font(.caption).foregroundStyle(Palette.muted)
                }
                // Stretch the detail block across the full row width.
                .frame(maxWidth: .infinity)
            }

            // Render one tappable column per chord in the selected progression.
            chordColumnsView

            // Show the piano keyboard; each tapped key is passed to transpose(to:).
            PianoKeyboard { midi in transpose(to: midi) }
                // Constrain the keyboard height so it fits with the rest of the lesson.
                .frame(minHeight: 140, idealHeight: 180, maxHeight: 220)

            // Show the key the progression is currently heard in.
            HStack {
                // Display the active key name using the shared note-name table.
                Text("Playing in \(lastKey)")
                    // Make the key label a small, bold accent so it is easy to spot.
                    .font(.caption.bold()).foregroundStyle(Palette.accent)
                // Push the hint text to the right edge of the row.
                Spacer()
                // Clarify that piano taps change the key rather than playing individual notes.
                Text("Tap a key to transpose")
                    // Style the hint as a muted caption.
                    .font(.caption).foregroundStyle(Palette.muted)
            }

            // Build the tempo-control row.
            HStack(spacing: 12) {
                // Label the slider with a metronome icon.
                Label("Tempo", systemImage: "metronome")
                    // Use bold caption text for the label.
                    .font(.caption.bold())
                    // Mute the label so the numeric tempo draws the eye.
                    .foregroundStyle(Palette.muted)
                // Bind the slider to bpm so dragging it updates state and the label together.
                Slider(value: $bpm, in: 60...180, step: 5)
                    // Match the slider thumb and track to the app's accent color.
                    .tint(Palette.accent)
                    // Give the control a clear name for VoiceOver.
                    .accessibilityLabel("Tempo")
                    // Speak the tempo in musical beats-per-minute terms.
                    .accessibilityValue("\(Int(bpm)) beats per minute")
                // Show the numeric tempo next to the slider.
                Text("\(Int(bpm)) BPM")
                    // Use monospaced digits so the value does not shift while dragging.
                    .font(.caption.bold().monospacedDigit())
                    // Highlight the value in the accent color.
                    .foregroundStyle(Palette.accent)
                    // Reserve a fixed width to keep the layout steady.
                    .frame(width: 64, alignment: .trailing)
            }

            // Absorb leftover vertical space so the completion button sits near the bottom.
            Spacer(minLength: 0)

            // Offer the button that completes this module and leaves the screen.
            PrimaryAction(title: "Done — Complete Module") {
                // Silence any chord that is still ringing before navigating away.
                audio.stop()
                // Record module 1 as finished in the shared progress state.
                state.finish(1)
                // Let the completion animation play, then close the view on the main queue.
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { dismiss() }
            }
        }
        // Add breathing room around the stacked lesson content.
        .padding(20)
        }

        // Apply the shared visual treatment used by all lesson screens.
        .modifier(LessonBackground())
        // Suppress the navigation title because this screen supplies its own heading.
        .navigationTitle("")
        // Initialize the view's state when it first appears on screen.
        .onAppear {
            // Begin in C major, represented by a semitone offset of zero.
            selectedKey = 0
            // Keep the displayed key name consistent with that offset.
            lastKey = Self.keyNames[selectedKey]
            // Start with no additional transposition beyond the chosen key.
            transposeOffset = 0
            // Restore the progression selected earlier in the app, if there is one.
            chosen = state.selectedProgression
            // If that progression is not valid in the new key, pick a diatonic one.
            if !filteredProgressions.contains(where: { $0.id == chosen }) {
                // Only fall back when at least one valid progression exists.
                if let first = filteredProgressions.first {
                    // Select the first progression that fits the key.
                    chosen = first.id
                    // Persist that fallback choice so later screens see the same selection.
                    state.selectedProgression = chosen
                }
            }
        }
        // Stop audio when the screen disappears so sound does not leak into other modules.
        .onDisappear { audio.stop() }
    }

    /// Shows each chord in the progression as a tappable column of its notes.
    // Build a horizontal row of chord buttons that audition their notes when tapped.
    private var chordColumnsView: some View {
        // Lay the chord columns out side by side, aligned along their top edges.
        HStack(alignment: .top, spacing: 8) {
            // Enumerate the chords so each column can be labeled "Chord 1", "Chord 2", and so on.
            ForEach(Array(currentChordNotes().enumerated()), id: \.offset) { index, notes in
                // Wrap the column in a button so a tap plays that chord.
                Button {
                    // Stop the previous chord so notes from different chords do not overlap.
                    audio.stop()
                    // Play this column's MIDI notes through the shared audio engine.
                    audio.playChord(notes)
                    // Compile the haptic call only on iOS, where UIKit feedback is available.
                    #if os(iOS)
                    // Give a light tactile click to confirm the selection.
                    UISelectionFeedbackGenerator().selectionChanged()
                   
                    #endif
                } label: {
                    // Stack the chord symbol, its position, and the individual note labels.
                    VStack(spacing: 6) {
                        // Derive and display a friendly chord symbol from the MIDI notes.
                        Text(chordLabel(for: notes))
                            // Draw the symbol prominently in a bold headline font.
                            .font(.headline.bold())
                            // Use light text so it reads against the dark panel.
                            .foregroundStyle(Palette.cream)
                        // Display the chord's ordinal position within the progression.
                        Text("Chord \(index + 1)")
                            // Use very small muted text for secondary information.
                            .font(.caption2)
                            .foregroundStyle(Palette.muted)
                        // Stack a label for each MIDI note in this chord.
                        VStack(spacing: 4) {
                            // Iterate by position because a chord can contain repeated pitch classes.
                            ForEach(Array(notes.enumerated()), id: \.offset) { _, midi in
                                // Convert the raw MIDI number into a readable note name.
                                Text(noteName(for: midi))
                                    // Use compact bold text for the note pill.
                                    .font(.caption.bold())
                                    // Let the note label fill the width of the column.
                                    .frame(maxWidth: .infinity)
                                    // Add vertical padding to make the pill comfortable to read.
                                    .padding(.vertical, 5)
                                    // Draw a translucent accent rounded rectangle behind the note.
                                    .background(Palette.accent.opacity(0.22), in: RoundedRectangle(cornerRadius: 6))
                                    // Keep the note text light against the tinted pill.
                                    .foregroundStyle(Palette.cream)
                            }
                        }
                    }
                    // Let every column take an equal share of the horizontal space.
                    .frame(maxWidth: .infinity)
                    // Add vertical padding inside the chord panel.
                    .padding(.vertical, 10)
                    // Add horizontal padding inside the chord panel.
                    .padding(.horizontal, 6)
                    // Draw a rounded panel behind the whole column.
                    .background(Palette.panel, in: RoundedRectangle(cornerRadius: 12))
                    // Outline the panel faintly to suggest that it is tappable.
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.accent.opacity(0.35), lineWidth: 1))
                }
                // Remove default button styling so only the custom panel is visible.
                .buttonStyle(.plain)
                // Make the button itself expand to the column's full width.
                .frame(maxWidth: .infinity)
                // Describe the button's musical action for assistive technology.
                .accessibilityLabel("Play chord \(chordLabel(for: notes))")
            }
        }
        // Stretch the row across the available width.
        .frame(maxWidth: .infinity)
    }

    /// Lets the user choose the song key and filters available progressions.
    // Build a menu listing all twelve keys; choosing one refilters the progression list.
    private var keyMenu: some View {
        // Present the key options as a pop-up menu.
        Menu {
            // Offer every entry in the twelve-note name table.
            ForEach(0..<Self.keyNames.count, id: \.self) { index in
                // Make each key name selectable.
                Button {
                    // Update the key and repair the progression selection if needed.
                    selectKey(index)
                } label: {
                    // Show a checkmark next to the key that is currently active.
                    if selectedKey == index {
                        // Combine the key name with a checkmark symbol.
                        Label(Self.keyNames[index], systemImage: "checkmark")
                    } else {
                        // Show inactive keys as plain text so the checked one stands out.
                        Text(Self.keyNames[index])
                    }
                }
            }
        } label: {
            // Show the current key on the menu's visible trigger button.
            Label("Key: \(Self.keyNames[selectedKey])", systemImage: "music.note")
                // Make the trigger a bold subtitle.
                .font(.subheadline.bold())
                // Pad the trigger horizontally and vertically to look like a chip.
                .padding(.horizontal, 12).padding(.vertical, 8)
                // Fill the chip with the panel color.
                .background(Palette.panel, in: Capsule())
                // Add a thin accent outline around the capsule.
                .overlay(Capsule().stroke(Palette.accent.opacity(0.35)))
        }
        // Tint menu items to the light cream color used elsewhere in the app.
        .tint(Palette.cream)
    }

    /// Lists progressions available in the selected key.
    // Build a menu of only those progressions whose chords fit the chosen key.
    private var progressionMenu: some View {
        // Present the valid progressions as a pop-up menu.
        Menu {
            // Iterate over the key-filtered list rather than the full library.
            ForEach(filteredProgressions) { progression in
                // Make each progression selectable.
                Button {
                    // Switch the app to this progression by storing its id in local and shared state.
                    chosen = progression.id
                    // Keep the shared selection in sync for other screens.
                    state.selectedProgression = chosen
                } label: {
                    // Mark the currently selected progression with a checkmark.
                    if chosen == progression.id {
                        // Show the name plus its chord symbols with a checkmark.
                        Label("\(progression.name) · \(progression.chords.joined(separator: "–"))", systemImage: "checkmark")
                    } else {
                        // Show unselected progressions as plain name-and-chords text.
                        Text("\(progression.name) · \(progression.chords.joined(separator: "–"))")
                    }
                }
            }
        } label: {
            // Show a fixed trigger label because the selection is shown inside the menu.
            Label("Progressions", systemImage: "music.note.list")
                // Make the trigger a bold subtitle.
                .font(.subheadline.bold())
                // Pad the trigger into a chip shape.
                .padding(.horizontal, 12).padding(.vertical, 8)
                // Fill the chip with the panel color.
                .background(Palette.panel, in: Capsule())
                // Add a faint accent outline to the capsule.
                .overlay(Capsule().stroke(Palette.accent.opacity(0.35)))
        }
        // Tint the menu's text and checkmarks to the light cream color.
        .tint(Palette.cream)
    }

    /// Updates the selected song key and keeps the chosen progression valid.
    // Change the key and fall back to a diatonic progression if the old one no longer fits.
    private func selectKey(_ index: Int) {
        // Store the new semitone offset so the filter recomputes.
        selectedKey = index
        // Update the human-readable key name shown in the status row.
        lastKey = Self.keyNames[index]
        // Clear any previous manual transposition so the key alone defines the sound.
        transposeOffset = 0
        // Check whether the previously chosen progression survives in the new key.
        if !filteredProgressions.contains(where: { $0.id == chosen }) {
            // Only choose a fallback when the filtered list is not empty.
            if let first = filteredProgressions.first {
                // Adopt the first valid progression in the new key.
                chosen = first.id
                // Publish that change to shared state so other modules stay consistent.
                state.selectedProgression = chosen
            }
        }
    }

    /// Transposes the chosen progression so it is rooted on `root` without playing it.
    // Interpret a tapped piano key as a new tonic and refilter the available progressions.
    private func transpose(to root: Int) {
        // Convert the tapped MIDI note into a pitch class using middle C (60) as the reference.
        selectedKey = ((root - 60) % 12 + 12) % 12
        // Mirror that pitch class as a readable key name for the status label.
        lastKey = Self.keyNames[selectedKey]
        // Reset manual offsets because the tapped key itself now sets the tonality.
        transposeOffset = 0
        // Verify the current progression still fits the newly chosen key.
        if !filteredProgressions.contains(where: { $0.id == chosen }) {
            // Fall back only if there is at least one diatonic option.
            if let first = filteredProgressions.first {
                // Select that first valid progression.
                chosen = first.id
                // Share the new selection with the rest of the app.
                state.selectedProgression = chosen
            }
        }
        // Provide tactile feedback only where UIKit is available.
        #if os(iOS)
        // Confirm the key tap with a subtle haptic click.
        UISelectionFeedbackGenerator().selectionChanged()
       
        #endif
    }

    /// The currently selected progression transposed to the chosen key.
    // Look up the selected progression and return its MIDI chords for display and playback.
    private func currentChordNotes() -> [[Int]] {
        // Guard against a missing id and return an empty list rather than crashing.
        guard let progression = progressions.first(where: { $0.id == chosen }) else { return [] }
        // Apply the transpose offset to every MIDI note in every chord.
        return progression.notes.map { notes in notes.map { $0 + transposeOffset } }
    }

    /// Names a chord from its MIDI notes (e.g. major "C", minor "Am").
    // Infer a chord symbol by finding its lowest note and checking for a minor third.
    private func chordLabel(for midiNotes: [Int]) -> String {
        // Sort the notes so the first element is reliably the root of the chord.
        let ordered = midiNotes.sorted()
        // Return an empty label if the chord has no notes at all.
        guard let root = ordered.first else { return "" }
        // Convert the root MIDI number into a pitch-class name from the shared table.
        let rootName = Self.keyNames[((root % 12) + 12) % 12]
        // Collect the distances above the root to identify the chord's quality.
        let intervals = Set(ordered.map { $0 - root })
        // A minor third (three semitones) means the chord is minor; otherwise treat it as major.
        let quality = intervals.contains(3) ? "m" : ""
        // Combine the root name with the quality suffix to form the final label.
        return rootName + quality
    }

    /// Returns the note name for a MIDI note number.
    // Reduce a MIDI number to a pitch class and look up its name, including for negative values.
    private func noteName(for midi: Int) -> String {
        Self.keyNames[((midi % 12) + 12) % 12]
    }
}
