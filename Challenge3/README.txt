CHORUS LINE — SwiftUI prototype

This folder contains the app source for the Chorus Line Xcode project.

Quick start:
1. Open `Challenge3.xcodeproj` in Xcode.
2. Select the `Challenge3` scheme and an iOS simulator or device.
3. Build and run. For microphone recording features, a physical iPhone is recommended.

Build from terminal (repo root):
  xcodebuild -project Challenge3.xcodeproj -scheme Challenge3 -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO

For a code walkthrough for new contributors, see `../CODE_NOTES.md`.

Current prototype features:
- Main menu with lesson modules, sandbox, and saved songs.
- Song structure lesson + spin-the-vinyl quiz.
- Chord progression module with key selection, filtered diatonic progressions, and one-octave piano.
- Drum beat pads with synthesized pop rhythms.
- Melody drawing canvas that converts strokes to synthesized notes (left-to-right playback).
- Sandbox for combining chord progression/key/tempo/beat and saving song ideas locally.
- Light/dark mode support and adaptive layouts for Apple device sizes.

Notes/limitations:
- Audio is synthesized for prototype playback; it is not a full multitrack production/export system.
- Saved song ideas store selections/notes metadata, not rendered audio files.
- Melody recording code exists, but the current melody module flow focuses on the drawing canvas.
