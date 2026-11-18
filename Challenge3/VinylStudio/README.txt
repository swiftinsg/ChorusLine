VINYL STUDIO — SwiftUI prototype

1. Open Xcode and create a new iOS App project named VinylStudio.
2. Choose SwiftUI as the interface and Swift as the language.
3. Delete the automatically created ContentView.swift and VinylStudioApp.swift from your Xcode project.
4. Drag this folder's VinylStudioApp.swift into the project, checking 'Copy items if needed' and the app target.
5. In your target's Info settings, add Privacy - Microphone Usage Description (NSMicrophoneUsageDescription): 'Record melodies you hum for your songs.'
6. Set iOS Deployment Target to iOS 17.0 or newer.
7. Build and run on an iPhone or iOS simulator. For microphone recording, a physical iPhone is recommended.

Features: 5-record menu, spinning completion records, song structure lesson + spinning quiz, chord progression piano with synthesized sound, 6 synthesized drum rhythms, melody recording, sandbox combining chord and beat selections, and locally saved song ideas.

Limitations: This is a prototype. The sandbox previews chords and beats separately, not as synchronized multitrack playback. Melody recording does not yet recognize pitch or convert audio into MIDI notes. Saving a song idea stores the selected chord progression and beat, not a rendered song/audio export. Production-quality drum samples, looping, synchronized playback and full arrangement/export would be next-stage enhancements.
