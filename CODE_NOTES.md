# Chorus Line — Code Notes

These notes explain the current Chorus Line prototype for a new contributor.

## Overview

Chorus Line is a SwiftUI iOS app that teaches basic songwriting concepts through four lesson modules and a sandbox:

1. **Song Structure** — lesson slides + spin-the-vinyl quiz.
2. **Chord Progression** — choose a key/progression and play chords on a one-octave piano.
3. **Drum Beats** — preview built-in drum patterns.
4. **Melody** — draw strokes on a landscape canvas; strokes are converted into synthesized notes.
5. **Sandbox** — combine chords, key, tempo, and drum beat, then save/play a song idea.

The app uses synthesized audio (`AVAudioEngine`) for chords/drums/tones and `AVAudioRecorder` for the legacy/voice recording support in `VoiceRecorder.swift`.

## Entry Points

- `Challenge3/Challenge3App.swift` — app entry point; launches `HomeView`.
- `Challenge3/ContentView.swift` — default Xcode template view; not used by the app flow.
- `Challenge3/Views/HomeView.swift` — main menu and navigation. It creates the shared `StudioState` and routes module IDs to lesson/sandbox/library views.

## Folder Map

- `Challenge3/Audio/`
  - `MusicEngine.swift` — real-time audio synthesis/playback.
  - `VoiceRecorder.swift` — microphone recording/playback helper (records `my-melody.m4a` in Documents).
- `Challenge3/Models/`
  - `Progression.swift` — chord progression data (`progressions` array).
  - `BeatPattern.swift` — drum pattern data (`beats` array).
  - `SongIdea.swift` — saved song model and `SongLibrary` UserDefaults persistence.
- `Challenge3/Support/`
  - `Palette.swift` — dynamic light/dark colors.
  - `StudioState.swift` — shared app state/progress.
- `Challenge3/Components/` — reusable UI pieces (vinyl, lesson cards/slideshow, piano keyboard, buttons/backgrounds, animations).
- `Challenge3/Views/` — screens for lessons, modules, sandbox, quiz, melody canvas, and saved songs.

## Shared State

`StudioState` (`Support/StudioState.swift`) is an `ObservableObject` passed through the view hierarchy:

- `completed` — completed module IDs, persisted in `UserDefaults` under `completedModules`.
- `completionEvent` — triggers the completion animation overlay in `HomeView`.
- `selectedProgression` / `selectedBeat` — last selections shared between modules/sandbox.
- `showModuleSpinHint` — controls whether lesson slides show the “swipe/spin the record” hint.
- `beginModule(_:)` — shows the hint only for the first lesson module opened (modules 0–3) on first app use. It persists a flag in `UserDefaults` key `didShowModuleSwipeHint`.
- `finish(_:animate:)` — marks a module complete; optionally fires completion animation.

## Navigation and Module Flow

`HomeView` uses `NavigationStack(path:)` and integer route IDs:

- `0` Song Structure → `StructureView`
- `1` Chord Progression → `ChordLessonView`
- `2` Drum Beats → `DrumLessonView`
- `3` Melody → `MelodyView`
- `4` Sandbox → `SandboxView`
- `5` Saved Songs → `SongLibraryView`

Lesson modules typically show `LessonSlideshow` first, then transition to the interactive view (quiz/piano/drum pads/melody recorder).

## Audio System (`Audio/MusicEngine.swift`)

`MusicEngine` synthesizes PCM buffers with `AVAudioEngine` + `AVAudioPlayerNode`. No external audio samples are required.

Key methods:

- `playChord(_:duration:)` — plays multiple MIDI notes as a chord.
- `playTone(_:duration:)` — plays a single MIDI note; used by melody drawing playback.
- `playProgression(_:bpm:)` — plays chord sequence over time.
- `playBeat(_:bpm:gain:)` — plays 8-step drum patterns. `gain` scales drum volume (default `1.0`).
- `playSong(progression:beat:bpm:drumGain:)` — renders a simple 4-bar preview combining chords and drums. `drumGain` scales drums (default `1.0`).
- `stop()` — stops current player node playback.

Drum hit mapping in patterns: `0 = kick`, `1 = snare`, `2 = hi-hat`.

## Models and Persistence

### Progressions (`Models/Progression.swift`)
Each `Progression` has `id`, `name`, `mood`, display `chords`, and MIDI `notes` (one chord per bar). The app includes multiple diatonic variations per key; Piano/Sandbox filter progressions by selected key.

### Beats (`Models/BeatPattern.swift`)
`beats` contains six pop-oriented 8-step patterns. Each step is an array of drum hit IDs.

### Song Ideas (`Models/SongIdea.swift`)
`SongIdea` stores:

- `title`
- `progression` — legacy preset index fallback
- `chordNotes` — custom chord notes entered/selected by user (preferred)
- `bpm`
- `beat`
- `createdAt`

`SongLibrary` saves/loads `[SongIdea]` as JSON in `UserDefaults` key `vinylStudioSongs`.

## Key UI Components

- `Vinyl.swift` — reusable record graphic; can spin and animate “needle drop” scale.
- `LessonSlideshow.swift` — swipe-driven lesson deck with a large half-visible vinyl. Swipe gesture rotates vinyl and advances slides; calls `onFinish` after the last slide.
- `CircularVinylGesture.swift` — converts drag movement around a circle into stepped rotation callbacks; used by quiz vinyl interaction.
- `PianoKeyboard.swift` — one-octave keyboard; reports MIDI note to caller. Piano/Sandbox use it for transposing/selecting key.
- `LessonBackground.swift`, `LessonCard.swift`, `PrimaryAction.swift` — shared styling/building blocks.
- `OpeningRecordAnimation.swift` / `RecordPlayerCompletion.swift` — module opening/completion overlays.

## Notable Current Behaviors

- **First-use slide hint:** only the first lesson module opened on first app use shows the vinyl swipe hint; controlled by `StudioState.beginModule` + `didShowModuleSwipeHint`.
- **Sandbox drum volume:** sandbox beat preview and song preview pass reduced drum gain (`0.35`) to better match melody/chord level.
- **Quiz vinyl hitbox:** `StructureQuizView` uses a larger interaction frame than the visible vinyl so users can spin from a larger radius.
- **Melody canvas:** strokes map to note duration/pitch, constrained to selected key; Play replays strokes left-to-right.
- **Light/Dark mode and device adaptation:** colors come from `Palette` dynamic colors; many layouts are scrollable/adaptive and iOS-only APIs are guarded.

## Build / Run

From repo root:

```bash
xcodebuild -project Challenge3.xcodeproj -scheme Challenge3 -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

Open `Challenge3.xcodeproj` in Xcode for normal run/debug. For microphone recording features, use a physical iPhone when possible.

## Limitations / Prototype Notes

- Sandbox/song playback is a simple synthesized preview, not a full multitrack production/export.
- Melody recording (`VoiceRecorder`) saves audio but does not detect pitch or convert to MIDI.
- Saved song ideas store metadata/chord notes/beat selection, not rendered audio files.
- Some files are legacy/template or lightly used (`ContentView.swift`, `VoiceRecorder.swift`) depending on current flow.
