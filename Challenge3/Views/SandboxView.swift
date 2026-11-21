// Import SwiftUI for the view, state, and layout APIs used throughout this screen.
import SwiftUI
// Only compile the UIKit import on platforms that actually provide UIKit.
#if canImport(UIKit)
// UIKit supplies the selection haptic used when a learner taps a chord.
import UIKit
// End of the UIKit-only import block.
#endif

/// Combines a chord progression and drum beat into a saved song idea.
// Declare a SwiftUI view whose body describes the golden sandbox screen.
struct SandboxView: View {
    // Read the shared app state so chord, key, and beat choices persist across modules.
    @EnvironmentObject var state: StudioState
    // Get SwiftUI's dismiss action in case this screen is presented modally.
    @Environment(\.dismiss) private var dismiss
    // Own one audio engine for the view's lifetime so auditioned sounds survive UI redraws.
    @StateObject private var audio = MusicEngine()
    // Hold the editable song title typed into the text field.
    @State private var songName = "My First Song"
    // Track the chosen progression by id; changing it rebuilds the chord columns.
    @State private var chosenProgression = 0
    // Track the key as a semitone offset from C, from 0 through 11.
    @State private var selectedKey = 0
    // Track which drum pattern from the beats library is selected.
    @State private var chosenBeat = 0
    // Remember the readable key name shown in the "Playing in ..." label.
    @State private var lastKey = "C"
    // Track extra semitone shifts applied to the progression, reset whenever the key changes.
    @State private var transposeOffset = 0
    // Hold the tempo bound to the slider, measured in beats per minute.
    @State private var bpm: Double = 100
    // Track whether a song has been saved so the success UI appears only after saving.
    @State private var saved = false
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
        // Allow vertical scrolling because the chord, beat, and save sections are tall.
        ScrollView {
            // Stack every section vertically with a generous 20-point gap.
            VStack(alignment: .leading, spacing: 20) {
                // Show the screen title in the app's gold accent color.
                Text("GOLDEN SANDBOX").font(.title.bold()).foregroundStyle(Palette.gold)
                // Explain the goal of the screen in a single muted sentence.
                Text("Build your first musical idea with chords and rhythm.").foregroundStyle(Palette.muted)
                // Bind the text field to songName so typing immediately updates the title state.
                TextField("Song title", text: $songName).textFieldStyle(.roundedBorder)

                // Introduce the first section of the workflow: chord selection.
                Text("1. CHOOSE YOUR CHORDS").font(.headline)
                // Group the two pickers closely together under that heading.
                VStack(alignment: .leading, spacing: 8) {
                    // Show the key-selection menu.
                    keyMenu
                    // Show the progression-selection menu.
                    progressionMenu
                }

                // If a progression matches the chosen id, show its descriptive details.
                if let selected = progressions.first(where: { $0.id == chosenProgression }) {
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
                    // Constrain the keyboard height so it fits with the rest of the screen.
                    .frame(minHeight: 140, idealHeight: 180, maxHeight: 220)

                // Show the key the progression is currently heard in.
                HStack {
                    // Display the active key name using the shared note-name table.
                    Text("Playing in \(lastKey)")
                        // Make the key label a small, bold accent so it is easy to spot.
                        .font(.caption.bold()).foregroundStyle(Palette.accent)
                    // Push the hint text to the right edge of the row.
                    Spacer()
                    // Clarify that piano taps set the song's key rather than playing notes.
                    Text("Tap a key to set your song's key")
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

                // Draw a divider between chord selection and rhythm selection.
                Divider()
                // Introduce the second section of the workflow: drum beat selection.
                Text("2. CHOOSE YOUR DRUM BEAT").font(.headline)
                // Lay out beat buttons in an adaptive grid that wraps on narrow screens.
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                    // Offer every predefined beat pattern from the beats library.
                    ForEach(beats) { beat in
                        // Make each beat selectable and audition it on tap.
                        Button(beat.name) {
                            // Record the tapped beat as the user's choice.
                            chosenBeat = beat.id
                            // Stop any previous loop before auditioning the new pattern.
                            audio.stop()
                            // Preview with reduced drum gain so beats sit closer to melody/chord levels.
                            audio.playBeat(beat.steps, gain: 0.35)
                       
                        }.frame(maxWidth: .infinity).padding(15)
                            // Highlight the selected beat in gold; use the neutral panel for the others.
                            .background(chosenBeat == beat.id ? Palette.gold.opacity(0.45) : Palette.panel, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                // Stop playback explicitly, including the looping drum pattern.
                Button("■ Stop") { audio.stop() }.buttonStyle(.bordered)
                // Draw a divider before the save section.
                Divider()
                // Introduce the third section of the workflow: saving the song idea.
                Text("3. SAVE YOUR SONG IDEA").font(.headline)
                // Tell the learner exactly which settings are captured in the saved idea.
                Text("Your current chord progression, key, tempo and drum choice will be saved in this song idea. You can add your recorded melody from Module 4 separately.")
                    // Use smaller muted text for this explanatory note.
                    .font(.subheadline).foregroundStyle(Palette.muted)
                // Provide the button that persists the song idea and completes the module.
                PrimaryAction(title: "Save Song Idea", tint: Palette.gold) {
                    // Assemble a snapshot of the current musical choices into a SongIdea value.
                    let idea = SongIdea(
                        // Use the title typed into the text field.
                        title: songName,
                        // Store the chosen progression's id for later reconstruction.
                        progression: chosenProgression,
                        // Store the actual transposed MIDI note arrays so playback matches what was heard.
                        chordNotes: currentChordNotes(),
                        // Capture the slider's tempo in beats per minute.
                        bpm: bpm,
                        // Capture the selected drum pattern's id.
                        beat: chosenBeat,
                        // Timestamp the idea with the current date.
                        createdAt: Date()
                    )
                    // Write the idea to UserDefaults-backed storage through the song library.
                    SongLibrary.save(idea)
                    // Mark module 4 complete without a flashy animation to avoid interrupting the save.
                    state.finish(4, animate: false)
                    // Flip the flag so the success message and playback button appear.
                    saved = true
                }
                // Show confirmation and playback controls only after a successful save.
                if saved {
                    // Confirm that the idea reached the song library.
                    Label("Saved to your song library!", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    // Let the learner hear the full saved arrangement: chords plus drums at the chosen tempo.
                    PrimaryAction(title: "▶ Play Your Song", tint: Palette.gold) {
                        // Build a one-off progression from the current notes and play it with the selected beat.
                        audio.playSong(progression: customProgression(), beat: beats[chosenBeat], bpm: bpm, drumGain: 0.35)
                    }
                }
                // Offer navigation to the library where all saved ideas are listed.
                NavigationLink("View Saved Songs", destination: SongLibraryView())
                    // Make the link span the width and pad it like the other buttons.
                    .frame(maxWidth: .infinity).padding(15).background(Palette.panel, in: RoundedRectangle(cornerRadius: 14))
            // Close the main stack and pad the whole group for consistent screen margins.
            }.padding()
        // Apply the shared lesson background and give the screen a navigation-bar title.
        }.modifier(LessonBackground()).navigationTitle("Sandbox")
            // Initialize the view's state when it first appears on screen.
            .onAppear {
                // Begin in C major, represented by a semitone offset of zero.
                selectedKey = 0
                // Keep the displayed key name consistent with that offset.
                lastKey = Self.keyNames[selectedKey]
                // Start with no additional transposition beyond the chosen key.
                transposeOffset = 0
                // Restore the progression selected earlier in the app, if there is one.
                chosenProgression = state.selectedProgression
                // Restore the drum beat selected earlier in the app, if there is one.
                chosenBeat = state.selectedBeat
                // If that progression is not valid in the new key, pick a diatonic one.
                if !filteredProgressions.contains(where: { $0.id == chosenProgression }) {
                    // Only choose a fallback when the filtered list is not empty.
                    if let first = filteredProgressions.first {
                        // Adopt the first progression that fits the key.
                        chosenProgression = first.id
                        // Publish that fallback choice so other modules stay consistent.
                        state.selectedProgression = chosenProgression
                    }
                }
            }
            // Changing the progression makes the saved snapshot stale, so clear the confirmation.
            .onChange(of: chosenProgression) { _, _ in saved = false }
            // Changing the drum beat also invalidates the saved snapshot.
            .onChange(of: chosenBeat) { _, _ in saved = false }
            // Changing the key invalidates the chord notes captured in the saved idea.
            .onChange(of: transposeOffset) { _, _ in saved = false }
            // Changing the tempo invalidates the saved idea's timing.
            .onChange(of: bpm) { _, _ in saved = false }
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
                    // Switch to this progression in both local state and shared app state.
                    chosenProgression = progression.id
                    // Keep other screens in sync with the new choice.
                    state.selectedProgression = chosenProgression
                    // Invalidate any previously saved idea because its chords have changed.
                    saved = false
                } label: {
                    // Mark the currently selected progression with a checkmark.
                    if chosenProgression == progression.id {
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
    // Change the key, invalidate the saved snapshot, and fall back to a diatonic progression.
    private func selectKey(_ index: Int) {
        // Store the new semitone offset so the key filter recomputes.
        selectedKey = index
        // Update the human-readable key name shown in the status row.
        lastKey = Self.keyNames[index]
        // Clear any previous manual transposition so the key alone defines the sound.
        transposeOffset = 0
        // A different key means the previously saved chord notes are out of date.
        saved = false
        // Check whether the previously chosen progression survives in the new key.
        if !filteredProgressions.contains(where: { $0.id == chosenProgression }) {
            // Only choose a fallback when the filtered list is not empty.
            if let first = filteredProgressions.first {
                // Adopt the first valid progression in the new key.
                chosenProgression = first.id
                // Publish that change to shared state so other modules stay consistent.
                state.selectedProgression = chosenProgression
            }
        }
    }

    /// Transposes the chosen progression so it is rooted on `root`, and sets it as the song's key.
    // Interpret a tapped piano key as the song's tonic and refilter the available progressions.
    private func transpose(to root: Int) {
        // Convert the tapped MIDI note into a pitch class using middle C (60) as the reference.
        selectedKey = ((root - 60) % 12 + 12) % 12
        // Mirror that pitch class as a readable key name for the status label.
        lastKey = Self.keyNames[selectedKey]
        // Reset manual offsets because the tapped key itself now sets the tonality.
        transposeOffset = 0
        // A new key means any already saved idea no longer matches the current sound.
        saved = false
        // Verify the current progression still fits the newly chosen key.
        if !filteredProgressions.contains(where: { $0.id == chosenProgression }) {
            // Fall back only if there is at least one diatonic option.
            if let first = filteredProgressions.first {
                // Select that first valid progression.
                chosenProgression = first.id
                // Share the new selection with the rest of the app.
                state.selectedProgression = chosenProgression
            }
        }
        // Provide tactile feedback only where UIKit is available.
        #if os(iOS)
        // Confirm the key tap with a subtle haptic click.
        UISelectionFeedbackGenerator().selectionChanged()
       
        #endif
    }

    /// The currently selected progression transposed to the chosen key.
    // Look up the selected progression and return its MIDI chords for display and saving.
    private func currentChordNotes() -> [[Int]] {
        // Guard against a missing id and return an empty list rather than crashing.
        guard let progression = progressions.first(where: { $0.id == chosenProgression }) else { return [] }
        // Apply the transpose offset to every MIDI note in every chord.
        return progression.notes.map { notes in notes.map { $0 + transposeOffset } }
    }

    /// Builds a custom progression for playback using the user's current chord selection.
    // Package the current notes as a Progression so the audio engine can play the whole song.
    private func customProgression() -> Progression {
        // Read the transposed MIDI chords once so labels and notes stay in sync.
        let notes = currentChordNotes()
        // Construct a transient Progression with a reserved id and descriptive metadata.
        return Progression(
            // Use -1 because this progression is only for playback, not part of the library.
            id: -1,
            // Reuse the song title as the progression name.
            name: songName,
            // Mark it as custom so it is recognizable in debug or display contexts.
            mood: "Custom",
            // Generate readable chord symbols from the same MIDI notes being played.
            chords: notes.map(chordLabel(for:)),
            // Pass the actual MIDI note arrays that the engine will sound.
            notes: notes
        )
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
