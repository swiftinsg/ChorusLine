// -----------------------------------------------------------------------------
// FILE SUMMARY — Audio/MusicEngine.swift
// -----------------------------------------------------------------------------
// PURPOSE: Synthesises chords, tones, drum patterns and four-bar song previews in
//          real time with AVAudioEngine. No external audio samples are bundled.
//
// HOW IT WORKS:
//   • init() — builds the audio graph, connects the player node to the main
//     mixer and starts the engine; guards every play call with `running`.
//   • playChord(_:duration:) — renders all MIDI notes of a chord into one PCM
//     buffer using a sine + octave harmonic, a plucked envelope and 15 ms/120 ms
//     fade in/out to avoid clicks.
//   • playTone(_:duration:) — the same synthesis for one MIDI note with a
//     slightly faster decay; used by the melody drawing canvas.
//   • playProgression(_:bpm:) — renders one chord per beat into a single buffer;
//     the active chord is chosen from elapsed time so timing is sample-accurate.
//   • playBeat(_:bpm:gain:) — renders an eight-step pattern (each step an eighth
//     note), mixes kick/snare/hat voices, scales by `gain` and clamps the output.
//   • playSong(progression:beat:bpm:drumGain:) — stops old audio, then renders
//     four bars of chords plus a looping drum pattern into one preview buffer.
//   • stop() — stops and immediately restarts the player so it is ready again.
//   • drumSample(hit:local:index:) — synthesises kick (pitch drop), snare (noise
//     + tone) or hi-hat (fast noise) from the numeric hit code.
//   • noise(index:salt:) — repeatable pseudo-random value in [-1, 1] from an
//     integer hash, so percussion noise sounds identical on every run.
//
// Used by PianoView, DrumPadsView, SandboxView, MelodyDrawView, SongLibraryView.
// -----------------------------------------------------------------------------

// Import Apple's audio framework for the engine, PCM buffers, and playback node.
import AVFoundation
// Import Combine so ObservableObject can publish state changes to SwiftUI.
import Combine

// MARK: - Audio synthesizer (no external sound files needed)

// Waveforms are generated directly into PCM buffers, so no audio assets are bundled.
// This final class groups the engine, player node, and running flag into one controller.
/// Synthesises chords, drum patterns and full song previews in real time.
final class MusicEngine: ObservableObject {
    // The audio graph that owns and connects all audio nodes.
    private let engine = AVAudioEngine()
    // The node that schedules our synthesized PCM buffers for playback.
    private let player = AVAudioPlayerNode()
    // Stereo, 44.1 kHz PCM format shared by every buffer we create.
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
    // Records whether the engine started successfully; guards every play method.
    private var running = false
    // Build the audio graph when the engine object is created.
    init() {
        // Add the player node to the engine's graph so it can process audio.
        engine.attach(player)
        // Route the player's output into the main mixer using our stereo format.
        engine.connect(player, to: engine.mainMixerNode, format: format)
        // Start the engine and player, flipping `running` only on success; otherwise report the error.
        do { try engine.start(); player.play(); running = true } catch { print("Audio engine: \(error)") }
    }
    // Synthesize a chord from MIDI note numbers and schedule it for playback.
    func playChord(_ notes: [Int], duration: Double = 0.75) {
        // Do nothing if the engine never started, to avoid scheduling into a dead graph.
        guard running else { return }
        // Samples per second, matching the format's sample rate.
        let sampleRate = 44100.0
        // Convert the requested duration in seconds into a PCM frame count.
        let count = AVAudioFrameCount(duration * sampleRate)
        // Allocate a PCM buffer with room for those frames; bail out if it fails.
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else { return }
        // Mark all allocated frames as valid audio data to be played.
        buffer.frameLength = count
        // Grab the raw float sample arrays for the left and right stereo channels.
        guard let left = buffer.floatChannelData?[0], let right = buffer.floatChannelData?[1] else { return }
        // Fill every frame of the buffer with one computed sample.
        for i in 0..<Int(count) {
            // Convert the frame index into elapsed time in seconds.
            let t = Double(i) / sampleRate
            // Fade in over the first 15 ms so the note does not start with a click.
            let attack = min(1, t / 0.015)
            // Fade out over the last 120 ms so the note does not end with a click.
            let release = min(1, (duration - t) / 0.12)
            // Combine both fades with exponential decay to shape a natural plucked envelope.
            let envelope = max(0, min(attack, release)) * exp(-t * 1.0)
            // Sum a waveform for every MIDI note in the chord.
            let wave = notes.reduce(0.0) { sum, midi in
                // Convert MIDI note to Hz: note 69 is A4 = 440 Hz, 12 notes per octave.
                let frequency = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
                // Add a fundamental sine plus a quieter octave harmonic for richness.
                return sum + sin(2 * .pi * frequency * t) + 0.22 * sin(4 * .pi * frequency * t)
            // Average the notes so chords of different sizes stay at a similar level.
            } / Double(max(1, notes.count))
            // Apply the envelope and master level, then cast to Float for PCM storage.
            let value = Float(wave * envelope * 0.22)
            // Write the same mono sample into both channels for a centered chord.
            left[i] = value; right[i] = value
        }
        // Queue the finished buffer on the player with no completion callback.
        player.scheduleBuffer(buffer, completionHandler: nil)
    }

    // Plays a single synthesized tone. Longer durations produce sustained notes.
    // Uses the same MIDI-to-frequency math and amplitude envelope as chords.
    func playTone(_ midi: Int, duration: Double = 0.4) {
        // Skip playback if the audio engine is not running.
        guard running else { return }
        // Fixed sample rate used for all time-to-frame conversions.
        let sampleRate = 44100.0
        // Number of frames needed to hold the requested tone duration.
        let count = AVAudioFrameCount(duration * sampleRate)
        // Allocate a PCM buffer; bail out if the system cannot allocate it.
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else { return }
        // Declare how many frames of the buffer contain valid samples.
        buffer.frameLength = count
        // Access both stereo channel sample pointers for direct writes.
        guard let left = buffer.floatChannelData?[0], let right = buffer.floatChannelData?[1] else { return }
        // Generate one sample for each frame of the tone.
        for i in 0..<Int(count) {
            // Frame index to seconds.
            let t = Double(i) / sampleRate
            // Quick 10 ms attack ramp to prevent an audible click at the start.
            let attack = min(1, t / 0.01)
            // Quick 80 ms release ramp to prevent a click at the end.
            let release = min(1, (duration - t) / 0.08)
            // Envelope combines the fades with a slightly faster exponential decay.
            let envelope = max(0, min(attack, release)) * exp(-t * 1.15)
            // MIDI number to frequency in Hz, using A4 = 440 Hz as the reference.
            let frequency = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
            // Fundamental sine plus a quieter second harmonic for a fuller tone.
            let wave = sin(2 * .pi * frequency * t) + 0.25 * sin(4 * .pi * frequency * t)
            // Scale by envelope and volume, converting to Float for the PCM buffer.
            let value = Float(wave * envelope * 0.22)
            // Duplicate the sample into left and right channels.
            left[i] = value; right[i] = value
        }
        // Enqueue the tone buffer for playback.
        player.scheduleBuffer(buffer, completionHandler: nil)
    }
    // Plays a sequence of chords, one per beat, at the requested tempo.
    // All chords are rendered into a single buffer so timing is sample-accurate.
    func playProgression(_ chords: [[Int]], bpm: Double = 100) {
        // Require a running engine and at least one chord to render.
        guard running, !chords.isEmpty else { return }
        // Sample rate for converting seconds into PCM frames.
        let sampleRate = 44100.0
        // Seconds per chord: one beat at the given BPM, with a floor of 20 BPM.
        let chordDuration = 60.0 / max(20, bpm)
        // Total audio length = one chord duration for each chord in the array.
        let duration = chordDuration * Double(chords.count)
        // Convert total duration into the number of frames to allocate.
        let count = AVAudioFrameCount(duration * sampleRate)
        // Allocate the output PCM buffer and unwrap both stereo channel pointers.
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count),
              // Left channel raw float samples.
              let left = buffer.floatChannelData?[0],
              // Right channel raw float samples; fail if either is unavailable.
              let right = buffer.floatChannelData?[1] else { return }
        // Tell the buffer how many frames were actually written.
        buffer.frameLength = count
        // Iterate over every output frame in the progression.
        for i in 0..<Int(count) {
            // Current time in seconds within the whole progression.
            let t = Double(i) / sampleRate
            // Which chord should sound now, clamped to the last valid index.
            let index = min(chords.count - 1, Int(t / chordDuration))
            // Time elapsed inside the current chord, used for its envelope and wave.
            let local = t - Double(index) * chordDuration
            // 20 ms fade-in at the start of each chord.
            let attack = min(1, local / 0.02)
            // 120 ms fade-out at the end of each chord.
            let release = min(1, (chordDuration - local) / 0.12)
            // A gentler decay so slower tempos still ring through the whole beat.
            let envelope = max(0, min(attack, release)) * exp(-local * 1.4)
            // Add the waveform of each MIDI note in the currently active chord.
            let wave = chords[index].reduce(0.0) { sum, midi in
                // Convert the MIDI note number into cycles per second.
                let frequency = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
                // Fundamental plus quiet octave harmonic, evaluated at local chord time.
                return sum + sin(2 * .pi * frequency * local) + 0.22 * sin(4 * .pi * frequency * local)
            // Normalize by chord size so every chord has comparable loudness.
            } / Double(max(1, chords[index].count))
            // Apply envelope and a slightly hotter master level for progression preview.
            let value = Float(wave * envelope * 0.24)
            // Write the sample to the left stereo channel.
            left[i] = value
            // Write the same sample to the right stereo channel.
            right[i] = value
        }
        // Schedule the completed progression buffer for playback.
        player.scheduleBuffer(buffer, completionHandler: nil)
    }
    // Synthesize a drum pattern: each step holds 0 = kick, 1 = snare, 2 = hi-hat.
    func playBeat(_ steps: [[Int]], bpm: Double = 105, gain: Double = 1.0) {
        // Only attempt playback when the engine is up and running.
        guard running else { return }
        // Sample rate for frame conversion.
        let sampleRate = 44100.0
        // Each step is an eighth note: half of one beat at this BPM.
        let secondsPerStep = 60.0 / bpm / 2.0
        // Total pattern length = step duration times the number of steps.
        let duration = secondsPerStep * Double(steps.count)
        // Frames required to represent the whole pattern.
        let count = AVAudioFrameCount(duration * sampleRate)
        // Allocate a PCM buffer for the pattern; stop if allocation fails.
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else { return }
        // Set the valid frame count on the buffer.
        buffer.frameLength = count
        // Obtain writable pointers to the left and right channel sample data.
        guard let left = buffer.floatChannelData?[0], let right = buffer.floatChannelData?[1] else { return }
        // Render each frame of the drum pattern.
        for i in 0..<Int(count) {
            // Elapsed time in seconds since the pattern started.
            let t = Double(i) / sampleRate
            // Find the current step, clamped so the last frame stays in range.
            let step = min(steps.count - 1, Int(t / secondsPerStep))
            // Time since the current step began, used as the drum hit's decay clock.
            let local = t - Double(step) * secondsPerStep
            // Accumulate all drum voices sounding at this frame.
            var signal = 0.0
            // The hit codes scheduled on this step.
            let hits = steps[step]
            // Mix together every drum hit active on this step.
            for hit in hits {
                // Generate that drum's sample at its age `local` and add it in.
                signal += drumSample(hit: hit, local: local, index: i)
            }
            // Apply the caller's drum volume after all hits are summed.
            signal *= gain
            // Clamp to +/-0.95 to leave headroom and avoid clipping distortion.
            let value = Float(max(-0.95, min(0.95, signal)))
            // Center the drum mix by writing the same sample to both channels.
            left[i] = value; right[i] = value
        }
        // Queue the drum buffer on the player.
        player.scheduleBuffer(buffer, completionHandler: nil)
    }
    // Render four bars of chords plus drums into one continuous preview buffer.
    func playSong(progression: Progression, beat: BeatPattern, bpm: Double = 108, drumGain: Double = 1.0) {
        // Bail out unless the audio engine is running.
        guard running else { return }
        // Clear anything already queued so previews do not overlap.
        stop()
        // Sample rate used for all time-to-frame math in this preview.
        let rate = 44100.0
        // Length of one beat in seconds at the chosen tempo.
        let beatDuration = 60.0 / bpm
        // One bar contains four beats in common time.
        let barDuration = 4 * beatDuration
        // The preview covers exactly four bars.
        let duration = 4 * barDuration
        // Total PCM frames required for those four bars.
        let frames = AVAudioFrameCount(duration * rate)
        // Allocate the output buffer and fetch its stereo channel pointers.
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              // `floatChannelData` holds one float buffer per channel.
              let channels = buffer.floatChannelData else { return }
        // Mark the full frame capacity as valid audio.
        buffer.frameLength = frames
        // Render every frame of the four-bar preview.
        for i in 0..<Int(frames) {
            // Elapsed seconds since the start of the song.
            let t = Double(i) / rate
            // Which of the four bars we are in, clamped at index 3.
            let bar = min(3, Int(t / barDuration))
            // Time within the current bar, used for chord envelope and waveform phase.
            let chordTime = t - Double(bar) * barDuration
            // The MIDI notes of the chord assigned to this bar.
            let notes = progression.notes[bar]
            // Fade the chord in over 30 ms and out over 180 ms at the bar edges.
            let chordEnvelope = min(1, chordTime / 0.03) * min(1, (barDuration - chordTime) / 0.18)
            // Sum the waveforms of all notes in this bar's chord.
            let chord = notes.reduce(0.0) { partial, midi in
                // Convert each MIDI number to an audio frequency in Hz.
                let frequency = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
                // Fundamental sine at the bar-relative time.
                return partial + sin(2 * .pi * frequency * chordTime)
                    // Plus a quieter octave harmonic for a brighter pad sound.
                    + 0.18 * sin(4 * .pi * frequency * chordTime)
            // Average the chord, apply its envelope and level, and store the result.
            } / Double(max(1, notes.count)) * chordEnvelope * 0.22
            // Drum steps are eighth notes: two per beat.
            let stepDuration = beatDuration / 2
            // Step index cycles through the 8-step pattern once per bar via modulo.
            let step = Int(t / stepDuration) % beat.steps.count
            // Time within the current step drives the drum hit decay.
            let local = t.truncatingRemainder(dividingBy: stepDuration)
            // Hit codes scheduled on this step of the beat pattern.
            let hits = beat.steps[step]
            // Accumulate all drum voices for this frame.
            var drums = 0.0
            // Add each active drum hit to the mix.
            for hit in hits {
                // Synthesize the hit using its age and this frame index as noise seed.
                drums += drumSample(hit: hit, local: local, index: i)
            }
            // Scale the drum bus by the requested drum gain.
            drums *= drumGain
            // Mix chord and drums, clamping to avoid clipping at the output.
            let value = Float(max(-0.95, min(0.95, chord + drums)))
            // Write the final sample into the left stereo channel.
            channels[0][i] = value
            // Write the identical sample into the right stereo channel.
            channels[1][i] = value
        }
        // Schedule the four-bar buffer for playback.
        player.scheduleBuffer(buffer, completionHandler: nil)
    }
    // Stop queued audio and immediately restart the player so it is ready again.
    func stop() { player.stop(); player.play() }

    // MARK: - Drum synthesis

    // Synthesises a conventional drum hit. 0 = kick, 1 = snare, 2 = closed hi-hat.
    // `local` is seconds since the hit began; `index` seeds repeatable noise.
    private func drumSample(hit: Int, local: Double, index: Int) -> Double {
        // Choose a synthesis recipe based on the numeric hit code.
        switch hit {
        // Code 0 is a bass drum (kick).
        case 0:
            // Kick: fast pitch drop with a short click for attack.
            // Pitch swoops from 168 Hz down to 48 Hz over the first few ms.
            let pitch = 48.0 + 120.0 * exp(-local * 32.0)
            // Low sine body that decays quickly after the hit.
            let body = sin(2.0 * .pi * pitch * local) * exp(-local * 6.5)
            // Tiny burst of noise for the beater click, fading very fast.
            let click = noise(index: index, salt: 11) * exp(-local * 90.0) * 0.25
            // Return body plus click at the final kick level.
            return (body + click) * 0.85
        // Code 1 is a snare drum.
        case 1:
            // Snare: broadband noise burst plus a short tonal body.
            // Deterministic noise sample for this frame.
            let n = noise(index: index, salt: 29)
            // Noise decays fast, giving the snare its crisp rattle.
            let noisePart = n * exp(-local * 18.0)
            // A short 190 Hz tone adds the drum's body underneath the noise.
            let tone = sin(2.0 * .pi * 190.0 * local) * exp(-local * 22.0) * 0.35
            // Blend mostly noise with some tone and scale the overall level.
            return (noisePart * 0.7 + tone) * 0.55
        // Code 2 is a closed hi-hat cymbal.
        case 2:
            // Closed hi-hat: bright, tight noise with a fast decay.
            // Fresh noise sample with a different salt for a distinct timbre.
            let n = noise(index: index, salt: 47)
            // Very fast exponential decay makes the "closed" chick sound.
            return n * exp(-local * 55.0) * 0.28
        // Any unrecognized hit code should contribute silence.
        default:
            // Return zero amplitude for unknown drum codes.
            return 0
        }
    }

    // Deterministic pseudo-random noise in [-1, 1] for synthesized percussion.
    // The same index and salt always yield the same value, so hits are repeatable.
    private func noise(index: Int, salt: Int) -> Double {
        // Mix the frame index and salt with wrapping integer arithmetic into a seed.
        var x = UInt32(bitPattern: Int32(truncatingIfNeeded: index &* 1_664_525 &+ 1_013_904_223 &+ salt &* 374_761))
        // First xorshift step scrambles the high bits.
        x ^= x >> 16
        // Multiply by an odd constant to spread the bits further.
        x &*= 0x7feb_352d
        // Second xorshift step mixes the middle bits.
        x ^= x >> 15
        // Another odd-constant multiply continues the scramble.
        x &*= 0x846c_a68b
        // Final xorshift finishes the integer hash.
        x ^= x >> 16
        // Reinterpret as signed 32-bit and divide by the max to land in [-1, 1].
        return Double(Int32(bitPattern: x)) / Double(Int32.max)
    }
}
