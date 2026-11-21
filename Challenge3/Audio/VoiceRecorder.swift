import AVFoundation
import Combine

/// Records and plays back a hummed melody.
/// Note: this recorder utility is available in the codebase, but the current melody module flow
/// primarily uses the drawing canvas (`MelodyDrawView`) for melody creation.
final class VoiceRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var hasRecording = false
    @Published var message = ""
    private var recorder: AVAudioRecorder?
    private var playback: AVAudioPlayer?
    private var url: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("my-melody.m4a")
    }
    override init() {
        super.init()
        hasRecording = FileManager.default.fileExists(atPath: url.path)
    }
    func toggle() {
        if isRecording { recorder?.stop(); isRecording = false; hasRecording = true; message = "Melody saved on this device."; return }
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                guard granted else { self.message = "Enable microphone permission in Settings."; return }
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                    try AVAudioSession.sharedInstance().setActive(true)
                    self.recorder = try AVAudioRecorder(url: self.url, settings: [
                        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 44100,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ])
                    self.recorder?.record(); self.isRecording = true
                    self.message = "Recording… hum your melody."
                } catch { self.message = "Recording error: \(error.localizedDescription)" }
            }
        }
    }
    func play() {
        do { playback = try AVAudioPlayer(contentsOf: url); playback?.play() }
        catch { message = "Playback error: \(error.localizedDescription)" }
    }
}
