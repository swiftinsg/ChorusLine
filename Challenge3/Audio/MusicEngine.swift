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

    /// Plays a single synthesized tone. Longer durations produce sustained notes.
    func playTone(_ midi: Int, duration: Double = 0.4) {
        guard running else { return }
        let sampleRate = 44100.0
        let count = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else { return }
        buffer.frameLength = count
        guard let left = buffer.floatChannelData?[0], let right = buffer.floatChannelData?[1] else { return }
        for i in 0..<Int(count) {
            let t = Double(i) / sampleRate
            let attack = min(1, t / 0.01)
            let release = min(1, (duration - t) / 0.08)
            let envelope = max(0, min(attack, release)) * exp(-t * 1.15)
            let frequency = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
            let wave = sin(2 * .pi * frequency * t) + 0.25 * sin(4 * .pi * frequency * t)
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
            for hit in hits {
                signal += drumSample(hit: hit, local: local, index: i)
            }
            let value = Float(max(-0.95, min(0.95, signal)))
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
            for hit in hits {
                drums += drumSample(hit: hit, local: local, index: i)
            }
            let value = Float(max(-0.95, min(0.95, chord + drums)))
            channels[0][i] = value
            channels[1][i] = value
        }
        player.scheduleBuffer(buffer, completionHandler: nil)
    }
    func stop() { player.stop(); player.play() }

    // MARK: - Drum synthesis

    /// Synthesises a conventional drum hit. 0 = kick, 1 = snare, 2 = closed hi-hat.
    private func drumSample(hit: Int, local: Double, index: Int) -> Double {
        switch hit {
        case 0:
            // Kick: fast pitch drop with a short click for attack.
            let pitch = 48.0 + 120.0 * exp(-local * 32.0)
            let body = sin(2.0 * .pi * pitch * local) * exp(-local * 6.5)
            let click = noise(index: index, salt: 11) * exp(-local * 90.0) * 0.25
            return (body + click) * 0.85
        case 1:
            // Snare: broadband noise burst plus a short tonal body.
            let n = noise(index: index, salt: 29)
            let noisePart = n * exp(-local * 18.0)
            let tone = sin(2.0 * .pi * 190.0 * local) * exp(-local * 22.0) * 0.35
            return (noisePart * 0.7 + tone) * 0.55
        case 2:
            // Closed hi-hat: bright, tight noise with a fast decay.
            let n = noise(index: index, salt: 47)
            return n * exp(-local * 55.0) * 0.28
        default:
            return 0
        }
    }

    /// Deterministic pseudo-random noise in [-1, 1] for synthesized percussion.
    private func noise(index: Int, salt: Int) -> Double {
        var x = UInt32(bitPattern: Int32(truncatingIfNeeded: index &* 1_664_525 &+ 1_013_904_223 &+ salt &* 374_761))
        x ^= x >> 16
        x &*= 0x7feb_352d
        x ^= x >> 15
        x &*= 0x846c_a68b
        x ^= x >> 16
        return Double(Int32(bitPattern: x)) / Double(Int32.max)
    }
}
