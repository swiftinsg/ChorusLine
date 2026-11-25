// -----------------------------------------------------------------------------
// FILE SUMMARY — Audio/VoiceRecorder.swift
// -----------------------------------------------------------------------------
// PURPOSE: Records a hummed melody to `my-melody.m4a` in Documents and plays it
//          back. This utility is available in the codebase, but the current
//          melody module uses the drawing canvas (MelodyDrawView) instead.
//
// HOW IT WORKS:
//   • url — computed Documents URL for the single file that is overwritten on
//     each new recording.
//   • init() — restores `hasRecording` by checking whether that file exists.
//   • toggle() — stops/saves an active recording, or asks for microphone access,
//     configures the `.playAndRecord` session, creates an AAC AVAudioRecorder and
//     starts it. UI changes are dispatched to the main queue.
//   • play() — creates an AVAudioPlayer from the saved file and starts it,
//     reporting errors through the published `message`.
// -----------------------------------------------------------------------------

// Import AVFoundation for AVAudioRecorder, AVAudioPlayer, and session/permission APIs.
import AVFoundation
// Import Combine so @Published properties can notify SwiftUI views.
import Combine

/// Records and plays back a hummed melody.
/// Note: this recorder utility is available in the codebase, but the current melody module flow
/// primarily uses the drawing canvas (`MelodyDrawView`) for melody creation.
final class VoiceRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    // NSObject supplies KVO/delegate basics, ObservableObject drives SwiftUI updates, and the delegate handles recording events.
    // Published flag indicating whether a recording is currently in progress.
    @Published var isRecording = false
    // Published flag indicating whether a saved melody file exists on disk.
    @Published var hasRecording = false
    // Published user-facing status or error message shown in the UI.
    @Published var message = ""
    // Retains the active recorder while capturing audio from the microphone.
    private var recorder: AVAudioRecorder?
    // Retains the player during playback so it is not deallocated mid-sound.
    private var playback: AVAudioPlayer?
    // Computes the destination file URL for the saved hum in the app's Documents folder.
    private var url: URL {
        // Locate the user's Documents directory for persistent, app-owned storage.
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            // Append a fixed filename so the app always overwrites the same recording.
            .appendingPathComponent("my-melody.m4a")
    }
    // Override NSObject's initializer to run extra setup after super initialization.
    override init() {
        // Initialize the superclass before touching any instance properties.
        super.init()
        // Restore hasRecording from disk so state survives an app relaunch.
        hasRecording = FileManager.default.fileExists(atPath: url.path)
    }
    // Toggle between stopping an active recording and starting a new one.
    func toggle() {
        // If already recording, stop, save the file, update UI state, and exit early.
        if isRecording { recorder?.stop(); isRecording = false; hasRecording = true; message = "Melody saved on this device."; return }
        // Ask the user for microphone access; weak self avoids keeping the recorder alive forever.
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            // Permission callbacks may arrive off the main thread; UI changes need the main queue.
            DispatchQueue.main.async {
                // Bail out if the recorder was deallocated while waiting for permission.
                guard let self else { return }
                // If permission was denied, explain how to enable it and stop.
                guard granted else { self.message = "Enable microphone permission in Settings."; return }
                // Audio session configuration calls can throw, so handle failures.
                do {
                    // Allow recording and playback together, routing output to the speaker by default.
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                    // Activate the shared audio session so the recorder can use the mic.
                    try AVAudioSession.sharedInstance().setActive(true)
                    // Create a recorder that writes compressed audio to our Documents URL.
                    self.recorder = try AVAudioRecorder(url: self.url, settings: [
                        // Use AAC compression, which is compact and standard for .m4a files.
                        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        // 44.1 kHz sampling captures a hum with more than enough fidelity.
                        AVSampleRateKey: 44100,
                        // Mono is sufficient for a single hummed melody.
                        AVNumberOfChannelsKey: 1,
                        // Request high encoding quality for a cleaner recording.
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ])
                    // Start capturing audio and reflect that in the published state.
                    self.recorder?.record(); self.isRecording = true
                    // Prompt the user to hum now that recording has begun.
                    self.message = "Recording… hum your melody."
                // Report any session or recorder setup error to the user.
                } catch { self.message = "Recording error: \(error.localizedDescription)" }
            }
        }
    }
    // Play back the most recently saved hum, if one exists.
    func play() {
        // Try to create a player from the saved file and start it; show an error on failure.
        do { playback = try AVAudioPlayer(contentsOf: url); playback?.play() }
        // Surface playback problems such as a missing or unreadable file.
        catch { message = "Playback error: \(error.localizedDescription)" }
    }
}
