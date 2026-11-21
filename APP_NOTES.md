# Chorus Line — App Notes

Chorus Line is a SwiftUI prototype app that introduces songwriting basics through short, interactive lessons and a simple song-building sandbox.

## Home Screen

The home screen shows:
- **Song Structure**
- **Chord Progression**
- **Drum Beats**
- **Melody**
- **Sandbox** (combine ideas into a song)
- **Saved Songs** (view and replay saved song ideas)

Tap a module to open it. Opening a module plays a short vinyl loading animation. Completed modules are marked on the home screen.

## Modules

### 1. Song Structure
- Walks through common song sections with swipeable lesson slides: Intro, Verse, Pre-Chorus, Chorus, Verse 2, Bridge, and Outro.
- Swipe/spin the record at the bottom to move between slides.
- Ends with a short quiz where you spin the vinyl to choose an answer and check it.
- On the first lesson module you open after installing/first using the app, a hint appears to show that you can spin the vinyl to move to the next slide. After that first module, the hint is hidden.

### 2. Chord Progression
- Teaches what chords and chord progressions are, then opens the chord piano.
- Choose a **key** and a **progression** (progressions are filtered to fit the selected key).
- Tap a chord column to hear that chord.
- Tap a piano key to transpose/set the progression to that key.
- Adjust tempo with the BPM slider.
- The piano is one octave and is used for transposing and exploring chords in the selected progression.

### 3. Drum Beats
- Introduces rhythm and common pop grooves.
- Tap a beat pad to preview a pattern (e.g. Classic Pop, Dance Pop, Synth Pop, Pop Rock, Pop Ballad, R&B Pop).
- Use **Stop** to stop playback.

### 4. Melody
- Introduces melody ideas (mood, humming phrases, space/repetition, capturing ideas).
- Opens a **Melody Canvas** (best used in landscape orientation).
- Choose a **key** to keep drawn notes in that key.
- Draw on the canvas:
  - **Long strokes** create more sustained notes.
  - **Short strokes** create quicker notes.
  - Vertical position affects pitch.
- Tap **Play** to hear your strokes played back from left to right.
- Tap **Clear** to remove strokes and start over.

## Sandbox

The Sandbox lets you build and save a song idea:
1. **Choose chords** — select key and progression, tap chord columns to preview, use the piano/tempo controls.
2. **Choose a drum beat** — tap a beat to preview it.
3. **Save your song idea** — saves the song title, current chord notes/progression context, tempo (BPM), and selected beat.

After saving, you can play the song idea preview and open **Saved Songs**.

## Saved Songs

- Shows song ideas saved on the device.
- Displays the song title, chord summary, beat name, and date.
- Tap **Play song** to preview a saved idea.
- Swipe/delete (list delete) removes saved entries.

## Tips & Notes

- **Light/Dark mode:** the app adapts its colors and surfaces for light and dark appearance.
- **Device support:** layouts are designed to adapt across Apple device sizes/orientations where supported.
- **Audio:** chords, drum beats, melody tones, and song previews are synthesized in the app (no external sample files required).
- **Melody canvas:** playback follows stroke position from left to right and is constrained to the selected key.

## Limitations (Prototype)

- Song playback is a simplified synthesized preview, not a full multitrack production or audio export.
- Saving a song idea stores the selected musical choices (chords/tempo/beat metadata), not a rendered audio file.
- Melody creation in the current flow is drawing-based on the canvas; recorded hum audio is not converted to MIDI/pitch-detected notes.
- Some behaviors/content are prototype-level and intended for learning and exploration rather than final production use.
