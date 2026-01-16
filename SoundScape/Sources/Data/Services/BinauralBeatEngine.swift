import AVFoundation
import Foundation

@Observable
@MainActor
final class BinauralBeatEngine {
    // MARK: - Public State

    private(set) var isPlaying: Bool = false
    var brainwaveState: BrainwaveState = .alpha
    var toneType: ToneType = .binaural
    var baseFrequency: BaseFrequency = .low
    var volume: Float = 0.5

    // MARK: - Private Properties

    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?

    // Phase accumulators for continuous sine wave generation
    private var leftPhase: Float = 0
    private var rightPhase: Float = 0
    private var isochronicPhase: Float = 0

    // MARK: - Computed Properties

    private var beatFrequency: Float {
        brainwaveState.frequency
    }

    private var leftFrequency: Float {
        baseFrequency.rawValue
    }

    private var rightFrequency: Float {
        baseFrequency.rawValue + beatFrequency
    }

    // MARK: - Public Methods

    func start() {
        guard !isPlaying else { return }

        configureAudioSession()
        setupAudioEngine()
        isPlaying = true
    }

    func stop() {
        guard isPlaying else { return }

        audioEngine?.stop()
        if let sourceNode = sourceNode {
            audioEngine?.detach(sourceNode)
        }
        audioEngine = nil
        sourceNode = nil
        isPlaying = false

        // Reset phases
        leftPhase = 0
        rightPhase = 0
        isochronicPhase = 0
    }

    func toggle() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }

    // MARK: - Private Methods

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("BinauralBeatEngine: Audio session configuration error: \(error.localizedDescription)")
        }
    }

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }

        let mainMixer = audioEngine.mainMixerNode
        let outputFormat = audioEngine.outputNode.outputFormat(forBus: 0)
        let sampleRate = Float(outputFormat.sampleRate)

        // Create format with 2 channels (stereo) for binaural beats
        guard let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 2) else {
            print("BinauralBeatEngine: Failed to create audio format")
            return
        }

        // Capture current values for use in audio thread
        let currentToneType = toneType
        let currentBaseFrequency = baseFrequency.rawValue
        let currentBeatFrequency = beatFrequency
        let currentVolume = volume

        // Create source node for real-time audio generation
        let source = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }

            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

            // Get current values (these might have changed)
            let toneType = currentToneType
            let leftFreq = currentBaseFrequency
            let rightFreq = currentBaseFrequency + currentBeatFrequency
            let vol = currentVolume
            let beatFreq = currentBeatFrequency

            for frame in 0..<Int(frameCount) {
                var leftSample: Float = 0
                var rightSample: Float = 0

                if toneType == .binaural {
                    // Binaural: different frequencies in each ear
                    leftSample = sin(self.leftPhase) * vol
                    rightSample = sin(self.rightPhase) * vol

                    // Increment phases
                    self.leftPhase += 2.0 * Float.pi * leftFreq / sampleRate
                    self.rightPhase += 2.0 * Float.pi * rightFreq / sampleRate

                    // Keep phases in reasonable range
                    if self.leftPhase > 2.0 * Float.pi {
                        self.leftPhase -= 2.0 * Float.pi
                    }
                    if self.rightPhase > 2.0 * Float.pi {
                        self.rightPhase -= 2.0 * Float.pi
                    }
                } else {
                    // Isochronic: same frequency with amplitude modulation
                    let carrierSample = sin(self.leftPhase)

                    // Create isochronic pulse (on/off pattern at beat frequency)
                    let isochronicEnvelope = (sin(self.isochronicPhase) + 1.0) / 2.0

                    let sample = carrierSample * isochronicEnvelope * vol
                    leftSample = sample
                    rightSample = sample

                    // Increment phases
                    self.leftPhase += 2.0 * Float.pi * leftFreq / sampleRate
                    self.isochronicPhase += 2.0 * Float.pi * beatFreq / sampleRate

                    // Keep phases in reasonable range
                    if self.leftPhase > 2.0 * Float.pi {
                        self.leftPhase -= 2.0 * Float.pi
                    }
                    if self.isochronicPhase > 2.0 * Float.pi {
                        self.isochronicPhase -= 2.0 * Float.pi
                    }
                }

                // Write to buffers
                if ablPointer.count >= 2 {
                    // Stereo output
                    let leftBuffer = ablPointer[0]
                    let rightBuffer = ablPointer[1]

                    if let leftData = leftBuffer.mData?.assumingMemoryBound(to: Float.self),
                       let rightData = rightBuffer.mData?.assumingMemoryBound(to: Float.self) {
                        leftData[frame] = leftSample
                        rightData[frame] = rightSample
                    }
                } else if ablPointer.count >= 1 {
                    // Interleaved stereo
                    let buffer = ablPointer[0]
                    if let data = buffer.mData?.assumingMemoryBound(to: Float.self) {
                        data[frame * 2] = leftSample
                        data[frame * 2 + 1] = rightSample
                    }
                }
            }

            return noErr
        }

        sourceNode = source

        audioEngine.attach(source)
        audioEngine.connect(source, to: mainMixer, format: format)
        mainMixer.outputVolume = 1.0

        do {
            try audioEngine.start()
        } catch {
            print("BinauralBeatEngine: Failed to start audio engine: \(error.localizedDescription)")
            self.audioEngine = nil
            self.sourceNode = nil
        }
    }

    // MARK: - Settings Update

    func updateSettings() {
        // If playing, restart with new settings
        if isPlaying {
            stop()
            start()
        }
    }
}
