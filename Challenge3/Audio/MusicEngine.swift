import AVFoundation
import Combine

// MARK: - Audio synthesizer (no external sound files needed)

/// Synthesises chords, drum patterns and full song previews in real time.
final class MusicEngine: ObservableObject {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
    private var running = false
    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        do { try engine.start(); player.play(); running = true } catch { print("Audio engine: \(error)") }
    }
    func playChord(_ notes: [Int], duration: Double = 0.75) {
        guard running else { return }
        let sampleRate = 44100.0
        let count = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else { return }
        buffer.frameLength = count
        guard let left = buffer.floatChannelData?[0], let right = buffer.floatChannelData?[1] else { return }
        for i in 0..<Int(count) {
            let t = Double(i) / sampleRate
            let attack = min(1, t / 0.015)
            let release = min(1, (duration - t) / 0.12)
            let envelope = max(0, min(attack, release)) * exp(-t * 1.0)
            let wave = notes.reduce(0.0) { sum, midi in
                let frequency = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
                return sum + sin(2 * .pi * frequency * t) + 0.22 * sin(4 * .pi * frequency * t)
            } / Double(max(1, notes.count))
            let value = Float(wave * envelope * 0.22)
            left[i] = value; right[i] = value
        }
        player.scheduleBuffer(buffer, completionHandler: nil)
    }
    /// Plays a sequence of chords, one per beat, at the requested tempo.
    func playProgression(_ chords: [[Int]], bpm: Double = 100) {
        guard running, !chords.isEmpty else { return }
        let sampleRate = 44100.0
        let chordDuration = 60.0 / max(20, bpm)
        let duration = chordDuration * Double(chords.count)
        let count = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count),
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1] else { return }
        buffer.frameLength = count
        for i in 0..<Int(count) {
            let t = Double(i) / sampleRate
            let index = min(chords.count - 1, Int(t / chordDuration))
            let local = t - Double(index) * chordDuration
            let attack = min(1, local / 0.02)
            let release = min(1, (chordDuration - local) / 0.12)
            // A gentler decay so slower tempos still ring through the whole beat.
            let envelope = max(0, min(attack, release)) * exp(-local * 1.4)
            let wave = chords[index].reduce(0.0) { sum, midi in
                let frequency = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
                return sum + sin(2 * .pi * frequency * local) + 0.22 * sin(4 * .pi * frequency * local)
            } / Double(max(1, chords[index].count))
            let value = Float(wave * envelope * 0.24)
            left[i] = value
            right[i] = value
        }
        player.scheduleBuffer(buffer, completionHandler: nil)
    }
    func playBeat(_ steps: [[Int]], bpm: Double = 105) {
        guard running else { return }
        let sampleRate = 44100.0
        let secondsPerStep = 60.0 / bpm / 2.0
        let duration = secondsPerStep * Double(steps.count)
        let count = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else { return }
        buffer.frameLength = count
        guard let left = buffer.floatChannelData?[0], let right = buffer.floatChannelData?[1] else { return }
        for i in 0..<Int(count) {
            let t = Double(i) / sampleRate
            let step = min(steps.count - 1, Int(t / secondsPerStep))
            let local = t - Double(step) * secondsPerStep
            var signal = 0.0
            let hits = steps[step]
            if hits.contains(0) { signal += sin(2 * .pi * (55 + 95 * exp(-local * 28)) * local) * exp(-local * 24) * 0.7 }
            if hits.contains(1) {
                let noise = sin(Double(i) * 83.37) * sin(Double(i) * 17.13)
                signal += noise * exp(-local * 26) * 0.48
            }
            if hits.contains(2) {
                let noise = sin(Double(i) * 59.17) * sin(Double(i) * 103.9)
                signal += noise * exp(-local * 85) * 0.22
            }
            let value = Float(max(-0.9, min(0.9, signal)))
            left[i] = value; right[i] = value
        }
        player.scheduleBuffer(buffer, completionHandler: nil)
    }
    func playSong(progression: Progression, beat: BeatPattern, bpm: Double = 108) {
        guard running else { return }
        stop()
        let rate = 44100.0
        let beatDuration = 60.0 / bpm
        let barDuration = 4 * beatDuration
        let duration = 4 * barDuration
        let frames = AVAudioFrameCount(duration * rate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let channels = buffer.floatChannelData else { return }
        buffer.frameLength = frames
        for i in 0..<Int(frames) {
            let t = Double(i) / rate
            let bar = min(3, Int(t / barDuration))
            let chordTime = t - Double(bar) * barDuration
            let notes = progression.notes[bar]
            let chordEnvelope = min(1, chordTime / 0.03) * min(1, (barDuration - chordTime) / 0.18)
            let chord = notes.reduce(0.0) { partial, midi in
                let frequency = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
                return partial + sin(2 * .pi * frequency * chordTime)
                    + 0.18 * sin(4 * .pi * frequency * chordTime)
            } / Double(max(1, notes.count)) * chordEnvelope * 0.22
            let stepDuration = beatDuration / 2
            let step = Int(t / stepDuration) % beat.steps.count
            let local = t.truncatingRemainder(dividingBy: stepDuration)
            let hits = beat.steps[step]
            var drums = 0.0
            if hits.contains(0) { drums += sin(2 * .pi * (58 + 85 * exp(-local * 26)) * local) * exp(-local * 25) * 0.52 }
            if hits.contains(1) { drums += sin(Double(i) * 83.37) * sin(Double(i) * 17.13) * exp(-local * 27) * 0.32 }
            if hits.contains(2) { drums += sin(Double(i) * 59.17) * sin(Double(i) * 103.9) * exp(-local * 92) * 0.14 }
            let value = Float(max(-0.9, min(0.9, chord + drums)))
            channels[0][i] = value
            channels[1][i] = value
        }
        player.scheduleBuffer(buffer, completionHandler: nil)
    }
    func stop() { player.stop(); player.play() }
}
